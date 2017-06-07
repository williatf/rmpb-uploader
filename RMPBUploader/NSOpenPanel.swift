//
//  NSOpenPanel.swift
//  RMPBUploader
//
//  Created by Todd Williams on 6/19/16.
//  Copyright © 2016 Todd Williams. All rights reserved.
//

import Cocoa

extension NSOpenPanel {
    var selectUrl: URL? {
        title = "Select File"
        allowsMultipleSelection = false
        canChooseDirectories = false
        canChooseFiles = true
        canCreateDirectories = false
        runModal()
        return urls.first
    }
    var directoryUrl: URL? {
        title = "Select Images Folder"
        allowsMultipleSelection = false
        canChooseDirectories = true
        canChooseFiles = false
        canCreateDirectories = false
        runModal()
        return urls.first
    }
}
