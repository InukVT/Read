//
//  DocumentViewController.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 24/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//

import UIKit
import Gzip

class DocumentViewController: UIViewController {
    
    var document: UIDocument?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {

            } else {
            }
        })
    }

}

