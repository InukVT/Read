//
//  ThumbnailProvider.swift
//  ReadThumbnails
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//

import UIKit
import QuickLook

class ThumbnailProvider: QLThumbnailProvider {
   override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        let fileURL = request.fileURL
        let maximumSize = request.maximumSize
        let scale = request.scale
        
        // Make use of the parameters of the request to determine the context size for the subsequent steps.
        let contextSize = contextSizeForFile(at: fileURL, maximumSize: maximumSize, scale: scale)
        
        let drawingBlock: () -> Bool = {
            let success = ThumbnailProvider.drawThumbnail(for: fileURL, contextSize: contextSize)
            // Indicate whether or not drawing the thumbnail succeeded.
            return success
        }
        
        // Create the QLThumbnailReply with the requested context size and the drawing block that draws the thumbnail.
        let reply = QLThumbnailReply(contextSize: contextSize, currentContextDrawing: drawingBlock)
        
        // Call the completion handler and provide the reply.
        // No need to return an error, since thumbnails are always provided.
        handler(reply, nil)
    }
    private func contextSizeForFile(at URL: URL, maximumSize: CGSize, scale: CGFloat) -> CGSize {
        
        // In the case of the Particles files, the maximum requested size can be honored.
        return maximumSize
    }
    
    private static func drawThumbnail(for fileURL: URL, contextSize: CGSize) -> Bool {
        
        // This method draws a thumbnail for the file at the given URL into the current context.
        
        var frame: CGRect = .zero
        frame.size = contextSize
        
        let document = Document(fileURL: fileURL)
        let openingSemaphore = DispatchSemaphore(value: 0)
        var openingSuccess = false
        document.open(completionHandler: { (success) in
            openingSuccess = success
            openingSemaphore.signal()
        })
        openingSemaphore.wait()
        

        guard openingSuccess else { return false }
       /* let documentFile = DocumentViewController()
        documentFile.document = document
        documentFile.thumb().draw(in: frame)
        */
        if let ePubCover = try? ePub(document) {
            if let cover = try? ePubCover.getCover(frame: frame) {
                cover.draw(in: frame)
            }
        }
        
        
        let closingSemaphore = DispatchSemaphore(value: 0)
        document.close { (_) in
            closingSemaphore.signal()
        }
        closingSemaphore.wait()
        
        return true
    }
}
