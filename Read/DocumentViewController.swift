//
//  DocumentViewController.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 24/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController {
    
    var document: Document?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                let book = ePub(self.document!)
                if let author = book.author {
                    print(author)
                }
                if let cover = try? book.getCover() {
                    print(cover)
                }
            } else {
            }
        })
    }

}
