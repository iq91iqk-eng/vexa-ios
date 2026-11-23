import SwiftUI
import WebKit

// قشرة فيكسا: WKWebView يعرض الواجهة المدموجة + جسر للدماغ على‑الجهاز (Brain).
struct WebHost: UIViewRepresentable {
    func makeCoordinator() -> Brain { Brain() }

    func makeUIView(context: Context) -> WKWebView {
        let ucc = WKUserContentController()
        ucc.add(context.coordinator, name: "vexa")

        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.userContentController = ucc

        let wv = WKWebView(frame: .zero, configuration: cfg)
        context.coordinator.webView = wv
        context.coordinator.speech.webView = wv
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
