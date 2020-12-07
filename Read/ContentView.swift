import SwiftUI

struct ContentView: View
{
    var fileURL: URL
    
    var body: some View
    {
        BookView(url: fileURL)
    }
}

struct ErrorView: View
{
    var body: some View
    {
        Text("An error occured")
    }
}
