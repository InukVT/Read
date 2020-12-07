import SwiftUI
import UniformTypeIdentifiers

struct BookDocument: FileDocument
{
    let config: ReadConfiguration
    init(configuration: ReadConfiguration) throws {
        self.config = configuration
        
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw BookError.notImplemented
    }
    
    static var readableContentTypes: [UTType] = [.epub]
}

enum BookError: Error
{
    case notImplemented
}
