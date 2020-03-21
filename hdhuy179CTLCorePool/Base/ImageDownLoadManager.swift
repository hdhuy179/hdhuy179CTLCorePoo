//
//  ImageDownLoadManager.swift
//  PegaXPool
//
//  Created by thailinh on 1/30/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import UIKit
enum PhotoRecordState {
    case new, downloaded, failed
}

class PhotoRecord {
    let name: String
    let url: URL
    var state = PhotoRecordState.new
    var image = UIImage(named: "Placeholder")
    
    init(name:String, url:URL) {
        self.name = name
        self.url = url
    }
}

class ImageDownLoadManager {
    lazy var downloadsInProgress: [Int: Operation] = [:]
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "CTLImageDownLoadManagerQueue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
}
