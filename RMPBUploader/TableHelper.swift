//
//  TableHelper.swift
//  RMPBUploader
//
//  Created by Todd Williams on 8/29/15.
//  Copyright (c) 2015 Todd Williams. All rights reserved.
//

import Cocoa
import Alamofire

class TableHelper: NSObject {
    
    // everything needs the File Manager
    let fileManager = FileManager.default
    
    var allImages:[Image] = []
    var imageFolderURL:URL?
    var flickrPhotoset: String = "unassigned"
    var flickrPhotosetTitle: String?
    
    func numberOfRowsInTableView(_ aTableView: NSTableView) -> Int {
        return allImages.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        switch tableColumn!.identifier {
        case "filename":
            return allImages[row].fileName as AnyObject
        case "filestate":
            return allImages[row].fileState as AnyObject
        case "flickrID":
            return allImages[row].flickrPhotoid as AnyObject
        default:
            print("TableHelper couldn't identify column")
            return nil
        }
    }
    
    func getImages() {
        
        // start with an empty array
        allImages = []
        var imageFileList:[URL] = []
        
        do {
            imageFileList = try fileManager.contentsOfDirectory(at: imageFolderURL!,
            includingPropertiesForKeys: [URLResourceKey.nameKey,URLResourceKey.fileSizeKey],
            options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

            var name : AnyObject?
            var size : AnyObject?
            var createDate : AnyObject?
            var index = 0
            for imageFile in imageFileList {
                if imageFile.pathExtension.lowercased() == "jpg" {
                    do {
                        try (imageFile as NSURL).getResourceValue(&name, forKey: URLResourceKey.nameKey)
                        try (imageFile as NSURL).getResourceValue(&size, forKey: URLResourceKey.fileSizeKey)
                        try (imageFile as NSURL).getResourceValue(&createDate, forKey: URLResourceKey.creationDateKey)
                        let temp:Image = Image()
                        temp.index = index
                        temp.fileName = name as! String
                        temp.fileSize = size as! Int
                        temp.fileState = "Ready"
                        temp.fileCreateDate = createDate as! Date
                        temp.fileURL = imageFile
                        allImages.append(temp)
                        index += 1
                    } catch {
                        print(error)
                    }
                }

            }
            //sort array by name
            allImages.sort(by: {$0.fileCreateDate.compare($1.fileCreateDate as Date) == ComparisonResult.orderedAscending})

        } catch {
            print(error)
        }

    } // end getImages
    

    
    
}
