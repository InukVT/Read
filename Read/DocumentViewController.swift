//
//  DocumentViewController.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 24/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//

import UIKit
import FolioReaderKit

class DocumentViewController: UIViewController {
    
    //@IBOutlet weak var documentNameLabel: UILabel!
    
    var document: UIDocument?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                // Display the content of the document, e.g.:
              //  self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
                let config = FolioReaderConfig()
                let bookPath = (self.document?.fileURL)!
                bookPath = bookPath.path
                print(bookPath)
                let folioReader = FolioReader()
                folioReader.presentReader(parentViewController: self, withEpubPath: "\(bookPath)", andConfig: config)
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
        }
    }
}

