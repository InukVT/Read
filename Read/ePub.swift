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

/// Monolith ePub handler class, with _some_ metadate. This needs to be broken into smalle KISS-y classes and structs for convenience!
class ePub: NSObject, XMLParserDelegate{
    private var parser = XMLParser()
    private let fileManager: FileManager
    private var workDir: URL
    private var compressedBook: Document
    private var metadata: String?
    private var tag: String?
    private var rootfile: String?
    private let bookFolder: String
    
    var title: String?
    var author: String?
    
    var cover: UIImage?
    private var coverLink: String?
    
    init(_ compressedBook: Document){
        self.fileManager = FileManager()
        self.compressedBook = compressedBook
        let currentWorkingPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        self.workDir = currentWorkingPath!
        
        self.bookFolder = URL(fileURLWithPath: self.compressedBook.fileURL.path).deletingPathExtension().lastPathComponent
        super.init()
        
        doXML()
    }

    private func doXML() {
        //self.parser = xmlGetter()
        readEpub() { xml in
            self.parser = xml
            self.parser.delegate = self
            self.parser.parse()
        }
        if let fullpath = rootfile {
            readEpub(fullpath) { xml in
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
                rootfile = fullpath
            }
            break
        case "item":
            if attributeDict["id"] == "cover" {
                coverLink = "\(attributeDict["href"] ?? "cover.xhtml")"
                
            }
        case "img":
            if attributeDict["id"] == "coverimage" {
                let imagePath = workDir.appendingPathComponent(bookFolder).appendingPathComponent("OEBPS").appendingPathComponent(attributeDict["src"]!).path
                if fileManager.fileExists(atPath: imagePath) {
                    cover = UIImage(data: fileManager.contents(atPath: imagePath)!)
                }
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
    
    /// Unpack the epub, get specified xml file, container.xml if no `relativePath` has been passed in, parse xml file, and delete the unpacked epub file afterwards
    private func readEpub(_ relativePath: String? = nil, closure: (XMLParser) -> ()) {
        let compressedBookPath = self.compressedBook.fileURL.path
        var uncompressedBookURL = workDir
        uncompressedBookURL.appendPathComponent(bookFolder)
        if !fileManager.fileExists(atPath: uncompressedBookURL.path){
            try! fileManager.copyItem(atPath: compressedBookPath, toPath: uncompressedBookURL.path)
        }
        
        var uncompressedBookData: String {
            if let path = relativePath {
                if path.contains("OEBPS") {
                    return path
                } else {
                    return "OEBPS/\(path)"
                }
            } else {
                return "META-INF/container.xml"
            }
        }
        
        closure(XMLParser(contentsOf: uncompressedBookURL.appendingPathComponent(uncompressedBookData))!)
        try? fileManager.removeItem(at: uncompressedBookURL)
    }
}

enum XMLError: Error {
    case FileExists
    case SomethingWentWrong
    case coverNotFound
}

extension ePub {
    /// Returns the cover image of a given book as `UIImage`
    func getCover(frame: CGRect) throws -> Void {
        if let coverPath = coverLink {
            let webView = WKWebView()
                webView.loadFileURL(URL(fileURLWithPath: workDir.path + "OEBPS/" + coverPath), allowingReadAccessTo: URL(fileURLWithPath: workDir.path))
            //let snapshotConfig = WKSnapshotConfiguration()
            //var returnImage: UIImage?
            webView.draw(frame)
            /*
            webView.takeSnapshot(with: snapshotConfig) { (image,error) in
                /*readEpub(coverPath){ xml in
                    self.parser = xml
                    self.parser.delegate = self
                    self.parser.parse()
                    if let image = cover {
                        returnImage = image
                    }
                }*/
                returnImage = image
                if error != nil {
                    print(error!)
                }
            }
 
            if returnImage != nil {
                return returnImage!
            } else {
                throw XMLError.coverNotFound
            }
 */
        } else {
            throw XMLError.coverNotFound
        }
    }
}
