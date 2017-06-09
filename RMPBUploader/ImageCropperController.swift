//
//  ImageCropperController.swift
//  RMPBUploader
//
//  Created by Todd Williams on 8/31/15.
//  Copyright (c) 2015 Todd Williams. All rights reserved.
//

import Cocoa

class ImageCropperController: NSWindowController {
    
    var refImageURL:URL?
    var i:Int = 0
    var refImage:NSImage?

    
    @IBOutlet weak var cropImage: NSImageView!
    @IBOutlet weak var prevButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!

    @IBAction func done(_ sender: NSButton) {

        // update status
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.statusLabel.stringValue = "Status: Ready"

        self.close()
    }

    
    override func windowDidLoad() {
        super.windowDidLoad()

        refImageURL = photoStripImages.imageFolderURL!.appendingPathComponent(
            photoStripImages.allImages[i].fileName
        )

//        println(refImageURL!.absoluteString)
        
        cropImage.image = resize(NSImage(byReferencing: refImageURL!))
        
        prevButton.isEnabled = false
        nextButton.isEnabled = true
        

    }
    
    @IBAction func prevImage(_ sender: NSButton) {
        if i != 0 {
            i -= 1
            nextButton.isEnabled = true
        }
//        println(i)
        if i == 0 { sender.isEnabled = false }

        refImageURL = photoStripImages.imageFolderURL!.appendingPathComponent(
            photoStripImages.allImages[i].fileName
        )
        cropImage.image = resize(NSImage(byReferencing: refImageURL!))
        
        

    }
    
    @IBAction func nextImage(_ sender: NSButton) {
        if i != photoStripImages.allImages.count {
            i += 1
            prevButton.isEnabled = true
        }
//        println(i)
        if i == photoStripImages.allImages.count { sender.isEnabled = false } else { sender.isEnabled = true }
        
        refImageURL = photoStripImages.imageFolderURL!.appendingPathComponent(
            photoStripImages.allImages[i].fileName
        )
        
        cropImage.image = resize(NSImage(byReferencing: refImageURL!))

    }


    
    func resize(_ image:NSImage) -> NSImage {
        image.size.width = 620
        image.size.height = 922
        return image
    }







}
