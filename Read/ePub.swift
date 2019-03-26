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

// MARK: - Book metadata
/// ePub handler class
class ePub {
    private let fileManager: FileManager
    private let workDir: URL
    private let compressedBook: Document
    private let bookFolder: String
    private var coverLink: String?
    /// ePub metadata, use this to get information
    private(set) var meta: EpubMeta? = nil
    private(set) var cover: UIImage?
    
    init(_ compressedBook: Document) throws {
        self.fileManager = FileManager()
        self.compressedBook = compressedBook
        self.workDir = fileManager.temporaryDirectory
        self.bookFolder = URL(fileURLWithPath: compressedBook.fileURL.path).deletingPathExtension().lastPathComponent
        //self.coverLink = nil
        //self.cover = nil
        self.meta = try doXML()
    }
}
// MAKR: - New ePub XML Parser
extension ePub {
    
    private func doXML() throws -> EpubMeta {
        var epub: EpubMeta?
        
        try unpackEpub { dataPath in
            var rootfileXML = container()
            let decoder = XMLDecoder()
                decoder.shouldProcessNamespaces = true
            do {
                let xmlData = try Data(contentsOf: dataPath.appendingPathComponent("META-INF/container.xml"))
                let xmlString = String(data: xmlData, encoding: .utf8)
                rootfileXML = try decoder.decode(container.self, from: (xmlString?.data(using: .utf8))!)
            } catch {
                throw XMLError.NotEpub
            }
            
            do {
                let xmlData = try Data(contentsOf: dataPath.appendingPathComponent((rootfileXML.rootfiles?.rootfile?.path!)!))
                let xmlString = String(data: xmlData, encoding: .utf8)
                var packageXML = package()
                    packageXML = try decoder.decode(package.self, from: (xmlString?.data(using: .utf8))!)
                epub = packageXML.metadata
            } catch {
                print(error)
                throw XMLError.SomethingWentWrong
            }
            
        }
        
        return epub!
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

fileprivate struct container: Codable {
    var rootfiles: rootfiles?
    enum CodingKeys: String, CodingKey {
        case rootfiles = "rootfiles"
    }
}

fileprivate struct rootfiles: Codable {
    var rootfile: rootfile?
    enum CodingKeys: String, CodingKey {
        case rootfile = "rootfile"
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

struct package: Codable {
    private(set) var metadata: EpubMeta?
}

struct Creators: Codable {
    let value: String
}
struct Title: Codable {
    let value: String
}
struct EpubMeta: Codable {
    private(set) var title: Title?
    private(set) var creator: [Creators]?
    //private(set) var bookDescription: String?
}
// MARK: - Custom errors
enum XMLError: String, Error {
    case FileExists
    case SomethingWentWrong
    case coverNotFound = "Cover not found"
    case NotEpub = "The given fils is not a valid epub file"
}
