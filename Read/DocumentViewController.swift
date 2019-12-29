//
//  DocumentViewController.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 24/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//

import UIKit
import BookKit
import EpubKit

class DocumentViewController: UIViewController {
    
    var document: Document?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Access the document
        document?.open { (success) in
            if success {
                do {
                    let book = try ePub(self.document!)
                    print(book.meta!.title as Any)
                } catch {
                    print(error)
                }
            }
            return nil
        }
    }

}
