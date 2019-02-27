//
//  ePub.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//
import Foundation
import UIKit

class ePub: NSObject, XMLParserDelegate {
    var parser = XMLParser()
    let workDir: URL
    var compressedBook: Document
    var metadata: String?
    var tag: String?
    var rootfile: String?
    
    var title: String?
    var author: String?
    var cover: UIImage?
    
    init(_ compressedBook: Document){
        
        self.compressedBook = compressedBook
        self.workDir = self.compressedBook.fileURL
    }
    func doXML() {
        self.parser = xmlGetter()

        self.parser.delegate = self
        self.parser.parse()
        if let fullpath = rootfile {
            self.parser = xmlGetter(relativePath: fullpath)
            self.parser.delegate = self
            self.parser.parse()
           
            if let title = self.title {
                print("You are reading: \(title)")
            } else {
                print("Failed to parse the books opf at: \n\(fullpath)")
            }
            rootfile = nil
        }
        
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]){
        switch elementName {
        case "rootfile":
            if let fullpath = attributeDict["full-path"] {
                rootfile = fullpath
                
            }
            break
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
            switch workingTag {
            case "dc:title":
                print(string)
                self.title = string
            default:
                //print(workingTag)
                break
            }
        }
    }
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
        //error = parseError
    }
    func xmlGetter(relativePath: String? = nil) -> XMLParser {
        let fileManager = FileManager()
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
