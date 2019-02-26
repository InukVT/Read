//
//  ePub.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//
import Foundation

class ePub: NSObject, XMLParserDelegate {
    var parser: XMLParser?
    var foundElementName: String?
    var compressedBook: Document
  //  let title: String
    //let author: String
    //let cover: UIImage
    
    init(_ CompressedBook: Document) {
        self.compressedBook = CompressedBook
        // Unzip (hopefully) the book into var Book
        self.parser = nil
        super.init()
        self.parser = xmlGetter()

        self.parser!.delegate = self
    }
    func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
        if elementName == "rootfile" && attributeName == "full-path" {
            print(defaultValue)
        }
    }
    func xmlGetter(relativePath: String? = nil) -> XMLParser {
        let fileManager = FileManager()
        let bookPath = self.compressedBook.fileURL.path
        let bookURL = URL(fileURLWithPath: bookPath).deletingPathExtension().lastPathComponent
        let currentWorkingPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        var archiveURL = currentWorkingPath!
        archiveURL.appendPathComponent(bookURL)
        try! fileManager.copyItem(atPath: bookPath, toPath: archiveURL.path)
        archiveURL.appendPathComponent(relativePath ?? "META-INF/container.xml")
        fileManager.fileExists(atPath: archiveURL.path )
        let uncompressedBookPath: URL = archiveURL
        let container =  try! fileManager.contents(atPath: uncompressedBookPath.path)
        return XMLParser(data: container!)
    }
}
