//
//  ePub.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//
import UIKit

struct ePub {
  //  let title: String
    //let author: String
    //let cover: UIImage
    var package: String
    init(_ CompressedBook: Document) {
        // Unzip (hopefully) the book into var Book
        let fileManager = FileManager()
        let bookPath = CompressedBook.fileURL.path
        let bookURL = URL(fileURLWithPath: bookPath).deletingPathExtension().lastPathComponent
        let currentWorkingPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        var archiveURL = currentWorkingPath!
            archiveURL.appendPathComponent(bookURL)
        try! fileManager.copyItem(atPath: bookPath, toPath: archiveURL.path)
        fileManager.fileExists(atPath: archiveURL.path + "META-INF/container.xml")
        var uncompressedBookPath: URL = archiveURL
            uncompressedBookPath.appendPathComponent("META-INF/container.xml")
        let container =  try! fileManager.contents(atPath: uncompressedBookPath.path)
        let packageString = String(data: container!, encoding: .utf8)
            self.package = packageString ?? "Failed to read the contents of the ZIP file!"
        

    }
}
