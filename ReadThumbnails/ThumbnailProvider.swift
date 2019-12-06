//
//  ThumbnailProvider.swift
//  ReadThumbnails
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//

import UIKit
import QuickLook
import BookKit
import BookView

class ThumbnailProvider: QLThumbnailProvider {
   override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        let fileURL = request.fileURL
        let maximumSize = request.maximumSize
        
        let drawingBlock: () -> Bool = {
            let success = ThumbnailProvider.drawThumbnail(for: fileURL, contextSize: maximumSize)
            // Indicate whether or not drawing the thumbnail succeeded.
            return success
        }
        
        // Create the QLThumbnailReply with the requested context size and the drawing block that draws the thumbnail.
        let reply = QLThumbnailReply(contextSize: maximumSize, currentContextDrawing: drawingBlock)
        
        // Call the completion handler and provide the reply.
        // No need to return an error, since thumbnails are always provided.
        handler(reply, nil)
    }
    
    private static func drawThumbnail(for fileURL: URL, contextSize: CGSize) -> Bool {
        
        // This method draws a thumbnail for the file at the given URL into the current context.
        
        var frame: CGRect = .zero
        frame.size = contextSize
        
        let document = Document(fileURL: fileURL)
        let openingSemaphore = DispatchSemaphore(value: 0)
        document.open(completionHandler: { (success) in
            openingSemaphore.signal()
        })
        openingSemaphore.wait()
        
        let book = try? ePub(document)
        let cover = try? book?.extractCover(frame: frame)
        if let drawCover = cover {
            drawCover.draw(in: frame)
        } else {
            UIImage(named: "image")?.draw(in: frame)
        }
        
        
        let closingSemaphore = DispatchSemaphore(value: 0)
        document.close { (_) in
            closingSemaphore.signal()
        }
        closingSemaphore.wait()
        
        return true
    }
}
