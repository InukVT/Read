import SwiftUI
import WebKit

final class WebViewWrapper: UIViewRepresentable
{
    @ObservedObject
    var state: WebViewStateModel
    
    var request: URLRequest? = nil
    var webView: WKWebView
    
    init(
        state: WebViewStateModel
    )
    {
        self.state = state
        let bundle = Bundle.main
        if let url = bundle.url(
            forResource: "reader/index",
            withExtension: "html")
        {
            request = URLRequest(url: url)
        } else {
            print("Failed to load bundle resource in \(bundle.bundlePath)")
        }
        
        let view = WKWebView()
        if let request = request {
            view.load(request)
        }
        self.webView = view
        load(book: state.url)
    }
    
    func load(book url: URL)
    {
        print("Loading \(url)")
        webView.evaluateJavaScript(
            """
            let book = ePub("\(url)", {})
            book.renderTo("viewer", {
                ignoreClass: "annotator-hl",
                width: "100%",
                height: "100%"
            });
            """,
            in: nil,
            in: .page)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // TODO: Implemente
    }
}
