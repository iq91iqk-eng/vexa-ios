import Foundation
import Speech
import AVFoundation
import WebKit

// الإدخال الصوتيّ الأصليّ لفيكسا: SFSpeechRecognizer (عربيّ) بدل Web Speech
// (WKWebView ما يكشف webkitSpeechRecognition). يبثّ النصّ للواجهة عبر window.__vexaSTT.
@MainActor
final class Speech: NSObject {
    weak var webView: WKWebView?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audio = AVAudioEngine()
    private var running = false

    func start() {
        guard !running else { return }
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                guard status == .authorized else { self.emitState(false); return }
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    Task { @MainActor in
                        guard granted else { self.emitState(false); return }
                        self.begin()
                    }
                }
            }
        }
    }

    private func begin() {
        guard let recognizer, recognizer.isAvailable else { emitState(false); return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch { emitState(false); return }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        request = req

        let node = audio.inputNode
        let fmt = node.outputFormat(forBus: 0)
        node.removeTap(onBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak req] buf, _ in req?.append(buf) }
        audio.prepare()
        do { try audio.start() } catch { emitState(false); return }
        running = true
        emitState(true)

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.emitText(result.bestTranscription.formattedString, final: result.isFinal)
                    if result.isFinal { self.stop() }
                }
                if error != nil { self.stop() }
            }
        }
    }

    func stop() {
        guard running else { emitState(false); return }
        running = false
        if audio.isRunning { audio.stop() }
        audio.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil; task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        emitState(false)
    }

    private func emitText(_ t: String, final: Bool) {
        let json = (try? String(data: JSONSerialization.data(withJSONObject: t, options: .fragmentsAllowed), encoding: .utf8)) ?? "\"\""
        webView?.evaluateJavaScript("window.__vexaSTT&&window.__vexaSTT(\(json),\(final ? "true" : "false"))", completionHandler: nil)
    }
    private func emitState(_ on: Bool) {
        webView?.evaluateJavaScript("window.__vexaListenState&&window.__vexaListenState(\(on ? "true" : "false"))", completionHandler: nil)
    }
}
