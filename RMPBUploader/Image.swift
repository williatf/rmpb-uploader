//
//  Image.swift
//  RMPBUploader
//
//  Created by Todd Williams on 8/29/15.
//  Copyright (c) 2015 Todd Williams. All rights reserved.
//

import Foundation


class Image: NSObject {
    var index = Int.init()
    var fileName = ""
    var fileState = "Ready"
    var fileSize = 0
    var fileCreateDate = Date.init()
    var fileURL: URL!
    var flickrPhotoid = ""
}
