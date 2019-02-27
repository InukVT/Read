//
//  ePub.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//
import Foundation
import UIKit

/// Monolith ePub handler class, with _some_ metadate. This needs to be broken into smalle KISS-y classes and structs for convenience!
class ePub: NSObject, XMLParserDelegate {
    private var parser = XMLParser()
    private let workDir: URL
    private var compressedBook: Document
    private var metadata: String?
    private var tag: String?
    private var rootfile: String?
    
    var title: String?
    var author: String?
    
    var cover: UIImage?
    var coverLink: String?
    
    init(_ compressedBook: Document){
        
        self.compressedBook = compressedBook
        self.workDir = self.compressedBook.fileURL
        super.init()
        doXML()
    }
    
    let fileManager = FileManager()
    
    
    
    private func doXML() {
        self.parser = xmlGetter()
        self.parser.delegate = self
        self.parser.parse()
        if let fullpath = rootfile {
            self.parser = xmlGetter(relativePath: fullpath)
            self.parser.delegate = self
            self.parser.parse()
        }
        if let fullpath = coverLink {
            self.parser = xmlGetter(relativePath: fullpath)
            self.parser.delegate = self
            self.parser.parse()
            if let image = cover {
                print(image.size)
            }
        }
        var deleteTMP = compressedBook.fileURL
        deleteTMP.deletePathExtension()
        try? fileManager.removeItem(at: deleteTMP)
        
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
                coverLink = "OEBS/\(attributeDict["href"] ?? "cover.xhtml")"
                
            }
        case "div":
            if attributeDict["class"] == "cover_image" {
                cover = UIImage(data: fileManager.contents(atPath: attributeDict["src"]!)!)
                print(1)
            }
        /*case "metadata":
            self.metadata = elementName
            break*/
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
    func xmlGetter(relativePath: String? = nil) -> XMLParser {
        
        let bookPath = self.compressedBook.fileURL.path
        let bookURL = URL(fileURLWithPath: bookPath).deletingPathExtension().lastPathComponent
        let currentWorkingPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        var archiveURL = currentWorkingPath!
        archiveURL.appendPathComponent(bookURL)
        if !fileManager.fileExists(atPath: archiveURL.path){
            try! fileManager.copyItem(atPath: bookPath, toPath: archiveURL.path)
        }
        archiveURL.appendPathComponent(relativePath ?? "META-INF/container.xml")
        fileManager.fileExists(atPath: archiveURL.path )
        let uncompressedBookPath: URL = archiveURL
        let container =  fileManager.contents(atPath: uncompressedBookPath.path)
        if let data = container {
            return XMLParser(data: data)
        } else {
            return XMLParser(contentsOf: uncompressedBookPath)!
        }
    }
}

enum XMLError: Error {
    case FileExists
    case SomethingWentWrong
}
