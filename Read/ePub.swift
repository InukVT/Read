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

/// Monolith ePub handler class, with _some_ metadate. This needs to be broken into smalle KISS-y classes and structs for convenience!
class ePub: NSObject, XMLParserDelegate{
    // MARK: - Book metadata
    private var parser = XMLParser()
    private let fileManager: FileManager
    private var workDir: URL
    private var compressedBook: Document
    private var metadata: String?
    private var tag: String?
    private var rootfile: String?
    private let bookFolder: String
    private var OEBPS: Bool?
    //private var workOEBPS: URL?
    
    var title: String?
    var author: String?
    
    var cover: UIImage?
    private var coverLink: String?
    
    init(_ compressedBook: Document){
        self.fileManager = FileManager()
        self.compressedBook = compressedBook
        self.workDir = fileManager.temporaryDirectory


        
        self.bookFolder = URL(fileURLWithPath: self.compressedBook.fileURL.path).deletingPathExtension().lastPathComponent
        super.init()
        
        doXML()
    }
    // MARK: - XML Parser Functions
    private func doXML() {
        //self.parser = xmlGetter()
        readEpub() { xml, _ in
            self.parser = xml
            self.parser.delegate = self
            self.parser.parse()
        }
        if let fullpath = rootfile {
            readEpub(fullpath) { xml, _ in
                self.parser = xml
                self.parser.delegate = self
                self.parser.parse()
            }
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]){
        switch elementName {
        case "rootfile":
            if let fullpath = attributeDict["full-path"] {
                if fullpath.contains("OEBPS"){OEBPS = true}
                rootfile = fullpath
            }
            break
        case "item":
            if attributeDict["id"] == "cover" {
                coverLink = "\(attributeDict["href"] ?? "cover.xhtml")"
                
            }
        default:
            self.tag = elementName
            break
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let workingTag = tag{
            if string != "\n    "{
                switch workingTag {
                case "dc:title":
                    title = string
                case "dc:creator":
                    author = string
                default:
                    //print(workingTag)
                    break
                }
            }
        }
    }
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
        //error = parseError
    }
    
    // MARK: - ePub unzipper
    /// Unpack the epub, get specified xml file, container.xml if no `relativePath` has been passed in, parse xml file, and delete the unpacked epub file afterwards
    private func readEpub(_ relativePath: String? = nil, closure: (XMLParser, URL) -> ()) {
        
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
        } else {
            print(fileManager.fileExists(atPath: compressedBookURL.appendingPathComponent("META-INF").appendingPathComponent("container.xml").path))
        }
        var uncompressedBookData: String {
            if let path = relativePath {
                if let _ = OEBPS {
                    return path
                } else {
                    return "OEBPS/\(path)"
                }
            } else {
                return "META-INF/container.xml"
            }
        }
        
        closure(XMLParser(contentsOf: uncompressedBookURL.appendingPathComponent(uncompressedBookData))!, uncompressedBookURL)
        if isZIP {
            try? fileManager.removeItem(at: uncompressedBookURL)
        }
    }
    
    func unzip(closure: () -> (URL)) -> URL {
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


extension ePub {
    // MARK: - Cover generator
    /// Returns the cover image of a given book as `UIImage`
    func getCover(frame: CGRect) throws -> UIImage {
        if let coverPath = coverLink {

            var cover: UIImage?
            readEpub{ _, workDir in
                
                let workOEBPS = workDir.appendingPathComponent(bookFolder).appendingPathComponent("OEBPS")
                let webView = WKWebView()
                let workCoverURL = workOEBPS.appendingPathComponent(coverPath)
                
                if fileManager.fileExists(atPath: workCoverURL.path) {
                    let coverHTMLString = try? String(contentsOf: workCoverURL, encoding: .utf8)
                    if let coverHTML = coverHTMLString {
                        webView.loadHTMLString(coverHTML, baseURL: workOEBPS)
                        let webFrame = webView.frame
                        webView.draw(webFrame)
                        if  webView.isLoading == true {
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

// MARK: - Custom errors
enum XMLError: Error {
    case FileExists
    case SomethingWentWrong
    case coverNotFound
}
