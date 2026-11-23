import SwiftUI
import WebKit

// قشرة فيكسا: WKWebView يعرض واجهة فيكسا المدموجة (نفس الواجهة الحيّة).
// الدماغ على‑الجهاز (llama.cpp) يُضاف بالمرحلة الجايّة كجسر JS↔Swift.
struct WebHost: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.isOpaque = false
        wv.backgroundColor = .black
        wv.scrollView.bounces = false
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www") {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
