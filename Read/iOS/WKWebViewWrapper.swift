import SwiftUI
import Combine
import WebKit

final class WebViewWrapper: UIViewRepresentable
{
    @ObservedObject
    var state: WebViewStateModel
    
    var cancallable = [Cancellable]()
    
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
        
        let contentController = WKUserContentController()
        
        
        let configuration = WKWebViewConfiguration()
        
        
        self.webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )
        
        configuration.userContentController = contentController
        if let request = request {
            webView.load(request)
        }
        self.cancallable.append(
            webView.publisher(for: \.isLoading)
            .sink{ [weak self] isLoading in
                guard !isLoading else { return }
                
                print("Has finished loading")
                self?.load(book: state.url)
            }
        )
    }
    
    private func load(book url: URL)
    {
        webView.callAsyncJavaScript(
            """
            let book = new Book(url, {})
            book.renderTo("viewer", {
                ignoreClass: "annotator-hl",
                width: "100%",
                height: "100%"
            })
            """,
            arguments: ["url": url.absoluteString],
            in: nil,
            in: .page,
            completionHandler: loadCompletion
        )
    }
    
    private func loadCompletion(result: Result<Any, Error>)
    {
        switch result {
            case .success(let any):
                print(any)
            case .failure(let error):
                print("Failed with \(error)")
        }
    }
    
    func makeUIView(context: Context) -> WKWebView {
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // TODO: Implemente
    }
}
