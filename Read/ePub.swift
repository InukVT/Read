//
//  ePub.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//
import Foundation
import UIKit
import WebKit
import ZIPFoundation
import XMLParsing

struct EpubMeta: Codable {
    private(set) var title: String?
    private(set) var author: [String]
    private(set) var bookDescription: String?
}

/// Monolith ePub handler class, with _some_ metadate. This needs to be broken into smalle KISS-y classes and structs for convenience!
struct ePub{
    // MARK: - Book metadata
    //private var parser = XMLParser()
    private var fileManager: FileManager
    private var workDir: URL
    private var compressedBook: Document
    private var metadata: String?
    private var tag: String?
    private var rootfile: String?
    private let bookFolder: String
    //private var workOEBPS: URL?
    /*
    private(set) var title: String?
    private(set) var author: [String]
    private(set) var bookDescription: String?
    */
    let meta: EpubMeta
    private(set) var cover: UIImage?
    private var coverLink: String?
    

    init(_ compressedBook: Document) throws {
        self.fileManager = FileManager()
        self.compressedBook = compressedBook
        self.workDir = fileManager.temporaryDirectory
        //title = ""
        //author = []
        //bookDescription = ""
        if let epub = try? doXML() {
            meta = epub
        } else {
            throw XMLError.SomethingWentWrong
        }
        self.bookFolder = URL(fileURLWithPath: self.compressedBook.fileURL.path).deletingPathExtension().lastPathComponent
//        super.init()
        

    }   
}
// MAKR: - New ePub XML Parser
extension ePub {
    
    private func doXML() throws -> EpubMeta {
        var epub: EpubMeta?
        var error: XMLError?
        readEpub { dataPath in
            var rootfile = Rootfile()
            let decoder = XMLDecoder()
            if let xmlData = try? Data(contentsOf: dataPath.appendingPathComponent("META-INF/container.xml")) {
                rootfile = try! decoder.decode(Rootfile.self, from: xmlData)
                
            } else {
                error = .NotEpub
            }
            
            if let xmlData = try? Data(contentsOf: dataPath.appendingPathComponent(rootfile.path!)) {
                
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
    private func readEpub(_ relativePath: String? = nil, closure: (URL) -> ()) {
        
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
        
        closure(uncompressedBookURL)
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
            readEpub{ workDir in
                
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

fileprivate struct Rootfile: Codable {
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
