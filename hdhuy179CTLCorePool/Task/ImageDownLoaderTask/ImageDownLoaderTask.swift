//
//  ImageDownLoaderTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/30/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import UIKit
class ImageDownloader: Operation {

    let photoRecord: PhotoRecord
    
    init(_ photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        guard let imageData = try? Data(contentsOf: photoRecord.url) else { return }
        
        if isCancelled {
            return
        }
        
        if !imageData.isEmpty {
            photoRecord.image = UIImage(data:imageData)
            photoRecord.state = .downloaded
        } else {
            photoRecord.state = .failed
            photoRecord.image = UIImage(named: "Failed")
        }
    }
}
