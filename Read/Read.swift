import SwiftUI

@main
struct Read: App
{
    var body: some Scene
    {
        DocumentGroup(viewing: BookDocument.self) { config in
            if let fileURL = config.fileURL {
                ContentView(fileURL: fileURL)
            } else {
                ErrorView()
            }
        }
    }
}
