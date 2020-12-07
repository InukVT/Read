import SwiftUI

struct BookView: View
{
    let url: URL
    var body: some View
    {
        WebViewWrapper (
            state: WebViewStateModel(url: url)
        )
    }
}

class WebViewStateModel: ObservableObject {
    @Published var url: URL
    init(url: URL) {
        self.url = url
    }
}
