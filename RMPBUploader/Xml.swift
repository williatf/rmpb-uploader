//
//  Xml.swift
//  RMPBUploader
//
//  Created by Todd Williams on 6/7/17.
//  Copyright © 2017 Todd Williams. All rights reserved.
//

import Foundation
import AEXML

class Xml: NSObject {
    
    let fileManager = FileManager.default

    func createXML(_ folder: URL) -> String {
        
        /**
         
         Example xml format
         
         <?xml version="1.0" ?>
         <breeze_systems_photobooth version="1.1">
         <photo_information>
         <date>2016/01/08</date>
         <time>12:53:43</time>
         <user_data></user_data>
         <prints>1</prints>
         <photobooth_images_folder>C:\Users\Mojo Photo Booth\Google Drive\RMPB\Events\!Confirmed\Valiant 9 Party</photobooth_images_folder>
         <caption1></caption1>
         <caption2></caption2>
         <photos>
         <photo image="1">RMPB_002.jpg</photo>
         <photo image="2">RMPB_003.jpg</photo>
         <photo image="3">RMPB_004.jpg</photo>
         <output>prints\20160108_125343.jpg</output>
         </photos>
         </photo_information>
         </breeze_systems_photobooth>
         
         
         The final XML format will look like this:
         <stripData>
         <photos>
         <photo image="1">RMPB_002.jpg</photo>
         <photo image="2">RMPB_003.jpg</photo>
         <photo image="3">RMPB_004.jpg</photo>
         <output>prints20160108_125343.jpg</output> *** notice that \ has been removed
         </photos>
         ... will be a <photos> block for every strip
         </stripData>
         
         **/
        
        print("starting createXML")
        
        var xmlFileList:[URL] = []
        let finalXMLDoc = AEXMLDocument()
        let envelope = finalXMLDoc.addChild(name: "stripData")
        
        do {
            xmlFileList = try fileManager.contentsOfDirectory(at: folder,
                  includingPropertiesForKeys: [URLResourceKey.nameKey],
                  options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles
            )
            
            for xmlFile in xmlFileList {
                if xmlFile.pathExtension.lowercased() == "xml" {
                    let data = try? Data(contentsOf: xmlFile)
                    do {
                        // read the xml file into an xml object
                        let xmlDoc = try AEXMLDocument(xml: data!)
                        
                        // get the photos block
                        let xmlPhotos = xmlDoc.root["photo_information"]["photos"].children
                        
                        // add a new photos block to the finalXMLDoc
                        let photos = envelope.addChild(name: "photos")
                        
                        // put the photos block into the finalXMLDoc
                        for xmlPhoto in xmlPhotos {
                            
                            // strip the slash from the <output> value
                            if xmlPhoto.name == "output" {
                                xmlPhoto.value = xmlPhoto.value!.replacingOccurrences(of: "\\", with: "")
                            }
                            photos.addChild(xmlPhoto)
                        }
                    } catch {
                        print("/(error)")
                    }
                }
            }
            
            print(finalXMLDoc.xml)
            
            
        } catch {
            print(error)
        }
        
        return finalXMLDoc.xml
        
    }
}

