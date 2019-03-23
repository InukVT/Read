//
//  ePub.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//
import Foundation
import WebKit
import ZIPFoundation
import XMLCoder

struct EpubMeta: Codable {
    private(set) var title: String?
    private(set) var author: [String]
    private(set) var bookDescription: String?
}

/// ePub handler class
struct ePub {
    // MARK: - Book metadata
    private var fileManager: FileManager
    private var workDir: URL
    private var compressedBook: Document
    private let bookFolder: String
    private var coverLink: String?
    /// ePub metadata, use this to get information such as author
    let meta: EpubMeta?
    private(set) var cover: UIImage?
    
    init(_ compressedBook: Document) throws {
        self.fileManager = FileManager()
        self.compressedBook = compressedBook
        self.workDir = fileManager.temporaryDirectory
        self.bookFolder = URL(fileURLWithPath: compressedBook.fileURL.path).deletingPathExtension().lastPathComponent
        do {
            self.meta = try doXML()
        } catch {
            self.meta = nil
            print(error)
            throw error
        }
    }
}
// MAKR: - New ePub XML Parser
extension ePub {
    
    private func doXML() throws -> EpubMeta {
        var epub: EpubMeta?
        var error: XMLError?
        
        unpackEpub { dataPath in
            var rootfileXML = rootfile()
            let decoder = XMLDecoder()
            if let xmlData = try? Data(contentsOf: dataPath.appendingPathComponent("META-INF/container.xml")) {
                rootfileXML = try! decoder.decode(rootfile.self, from: xmlData)
                
            } else {
                error = .NotEpub
            }
            
            if let xmlData = try? Data(contentsOf: dataPath.appendingPathComponent(rootfileXML.path!)) {
                
                epub = try! decoder.decode(EpubMeta.self, from: xmlData)
                print(epub!.author)
            } else {
                error = .SomethingWentWrong
            }
            
        }
      
        if let error = error {
            throw error
        } else {
            return epub!
        }
    }
}
// MARK: - ePub unzipper
extension ePub {
    
    /// Unpack the epub, get specified xml file, container.xml if no `relativePath` has been passed in, parse xml file, and delete the unpacked epub file afterwards
    private func unpackEpub(_ relativePath: String? = nil, closure: (URL) throws -> ()) rethrows {
        
        let compressedBookURL = self.compressedBook.fileURL
        var isZIP = false
        var uncompressedBookURL: URL = compressedBookURL
        if (!fileManager.fileExists(atPath: compressedBookURL.appendingPathComponent("META-INF").appendingPathComponent("container.xml").path)){
            uncompressedBookURL = unzip{
                uncompressedBookURL = workDir.appendingPathComponent(bookFolder)
                uncompressedBookURL.appendPathExtension("zip")
                
                if !fileManager.fileExists(atPath: uncompressedBookURL.path){
                    try! fileManager.copyItem(atPath: compressedBookURL.path, toPath: uncompressedBookURL.path)
                }
                return uncompressedBookURL
            }
            isZIP = true
        }
        
        try closure(uncompressedBookURL)
        if isZIP {
            try? fileManager.removeItem(at: uncompressedBookURL)
        }
    }

    private func unzip(closure: () -> (URL)) -> URL {
        let archive: URL = closure()
        var destinationURL = workDir
        destinationURL = destinationURL.appendingPathComponent(self.bookFolder)
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: archive, to: destinationURL)
            try fileManager.removeItem(at: archive)
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
        }
        
        return destinationURL
    }
}
// MARK: - Cover generator
extension ePub {
    /// Returns the cover image of a given book as `UIImage`
    func getCover(frame: CGRect) throws -> UIImage {
        if let coverPath = coverLink {
            
            var cover: UIImage?
            unpackEpub { workDir in
                
                let workOEBPS = workDir.appendingPathComponent("OEBPS")
                let webView = WKWebView()
                let workCoverURL = workOEBPS.appendingPathComponent(coverPath)
                
                if fileManager.fileExists(atPath: workCoverURL.path) {
                    let coverHTMLString = try? String(contentsOf: workCoverURL, encoding: .utf8)
                    if let coverHTML = coverHTMLString {
                        webView.loadHTMLString(coverHTML, baseURL: workOEBPS)
                        let webFrame = webView.frame
                        //wait(40)
                        webView.draw(webFrame)
                        if  webView.isLoading == true {
                            
                        }
                        let snapshotConfig = WKSnapshotConfiguration()
                        snapshotConfig.rect = frame
                        webView.takeSnapshot(with: snapshotConfig) { (image,error) in
                            if image != nil {
                                cover = image!
                            } else if error != nil {
                                print(error!)
                            }
                        }
                    }
                }
            }
            
            if cover != nil {
                return cover!
            } else {
                throw XMLError.coverNotFound
            }
        } else {
            throw XMLError.coverNotFound
        }
    }
}

fileprivate struct rootfile: Codable {
    var path: String?
    var mediaType: String?
    enum CodingKeys: String, CodingKey {
        case path = "full-path"
        case mediaType = "media-type"
    }
}

// MARK: - Custom errors
enum XMLError: Error {
    case FileExists
    case SomethingWentWrong
    case coverNotFound
    case NotEpub
}
