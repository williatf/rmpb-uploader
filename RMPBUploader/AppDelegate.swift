//
//  AppDelegate.swift
//  RMPBUploader
//
//  Created by Todd Williams on 8/29/15.
//  Copyright (c) 2015 Todd Williams. All rights reserved.
//

import Cocoa
import Alamofire

// Global vars for the directory, table views, the cropr view, the async ops, etc.
var individualImageDir: URL?
var individualImages = TableHelper()
var photoStripImages = TableHelper()
var imageCropperController:ImageCropperController?
var prefsController:PrefsController?
let stripsFolder:String = "_strips"
var stripsFolderDir: URL?
let pendingOperations = PendingOperations()
var eventBadgeURL: URL?


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource {
    
    // The main window object and it's child views
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var imageFolderLabel: NSTextField!
    @IBOutlet weak var photoStripImageTable: NSTableView!
    @IBOutlet weak var individualImageTable: NSTableView!
    @IBOutlet weak var eventDatePicker: NSDatePicker!
    @IBOutlet weak var eventPasswordLabel: NSTextField!
    @IBOutlet weak var eventBadge: NSImageView!
    @IBOutlet weak var statusLabel: NSTextField!
    
    var xml: String = String()
    var mainDir: URL?

    // update preferences
    // triggered on menu item: Preferences...
    @IBAction func updatePrefs(_ sender: NSMenuItem) {
        if prefsController == nil {
            prefsController = PrefsController.init(windowNibName: "PrefsController")
        }
        prefsController!.showWindow(nil)
    }

    // Select the main image folder when the button is clicked
    @IBAction func selectImageFolder(_ sender: AnyObject) {
        self.statusLabel.stringValue = "Status: Picking Event's Image Folder"
        self.imageFolder()
    }
    
    @IBAction func selectEventBadge(_ sender: AnyObject) {

        // update status
        self.statusLabel.stringValue = "Status: Picking Event's Badge Image"

        if let badgeURL = NSOpenPanel().selectUrl {
            eventBadge.image = NSImage(contentsOf: badgeURL as URL)
            eventBadgeURL = badgeURL
            print(eventBadgeURL!)
        } else {
            print("file selection was canceled")
        }

        // update status
        self.statusLabel.stringValue = "Status: Ready"

    }
    
    @IBAction func setCropParams(_ sender: AnyObject) {

        // can't crop unless we've got images in the strips folder
        if stripsFolderDir == nil {
            let alert = NSAlert()
            alert.messageText = "Error!"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Dismiss")
            alert.informativeText = "You need to select the event image folder first!"
            alert.beginSheetModal(for: self.window, completionHandler: nil)
        } else {
        
            // update status
            self.statusLabel.stringValue = "Status: Setting Cropping Parameters"

            if imageCropperController == nil {
                imageCropperController = ImageCropperController.init(windowNibName: "ImageCropperController")
            }
            imageCropperController!.showWindow(nil)

        }
    }
    
    @IBAction func beginProcess(_ sender: NSButton) {
        
        // check to make sure there's a password
        // and if not, update and then show the alert
        if self.eventPasswordLabel.stringValue == "" {
            let alert = NSAlert()
            alert.messageText = "Error!"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Dismiss")
            alert.informativeText = "You need to enter the event's password!"
            alert.beginSheetModal(for: self.window, completionHandler: nil)
        } else {
            // start with the crop, everything else is triggered from there
            self.performCrop()
        }
    }
    
    // FUNCTIONS

    private func imageFolder(){
    
        // Create the Panel that allows the user to choose a directory
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        // Show the panel to select a directory
        panel.beginSheetModal(for: self.window!, completionHandler: { (returnCode) -> Void in
            
            // Executes if the user selects the OK button at the end
            if (returnCode == NSModalResponseOK) {
                
                // set the main event image folder
                self.mainDir = panel.urls[0]
                
                // set the text in the folder label
                self.imageFolderLabel.stringValue = (panel.urls[0].lastPathComponent)
                
                // Check for green screen folder
                let fileManager = FileManager.default
                
                // set the path to a possible green screen folder
                let greenScreenPath:URL = panel.urls[0].appendingPathComponent("greenscreen",isDirectory: true )
                //                debugPrint(greenScreenPath)
                //                debugPrint(fileManager.fileExists(atPath:greenScreenPath.path))
                
                // check if the green screen folder exists at the path set above
                // this method returns true if the folder is there
                if fileManager.fileExists(atPath:greenScreenPath.path) {
                    debugPrint("greenscreen folder found")
                    var imageFileList:[URL] = []
                    do {
                        // Try to get a list of all files in the folder
                        imageFileList = try fileManager.contentsOfDirectory(
                            at: greenScreenPath,
                            includingPropertiesForKeys: [URLResourceKey.nameKey,URLResourceKey.fileSizeKey],
                            options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles
                        )
                    } catch {
                        print(error)
                    }
                    
                    // If there's files in it, then it becomes the image dir
                    if (imageFileList.count > 5) {
                        individualImageDir = greenScreenPath
                    }
                    
                    // otherwise the main folder is where the images are to be found
                } else {
                    individualImageDir = self.mainDir
                }
                
                // Get individaul images for table view
                individualImages.imageFolderURL = individualImageDir
                individualImages.getImages()
                individualImages.flickrPhotosetTitle = (self.mainDir?.lastPathComponent)! + "_INDIVIDUALS"
                debugPrint(individualImages.flickrPhotosetTitle!)
                self.individualImageTable.reloadData()
                
                // get photo strip images for table view
                photoStripImages.imageFolderURL = self.mainDir?.appendingPathComponent("prints",isDirectory: true)
                photoStripImages.getImages()
                photoStripImages.flickrPhotosetTitle = (self.mainDir?.lastPathComponent)! + "_STRIPS"
                debugPrint(photoStripImages.flickrPhotosetTitle!)
                self.photoStripImageTable.reloadData()
                
                // set the strips folder directory
                stripsFolderDir = self.mainDir?.appendingPathComponent(stripsFolder,isDirectory: true)
                debugPrint((stripsFolderDir?.path)!)
                
                // update Status
                self.statusLabel.stringValue = "Status: Ready"

            }
        })
        
    }
    
    private func performCrop() {
        
        //        print("\(crop.left), \(crop.right)")
        
        // create strips directory
        // check to see if it already exists
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath:(stripsFolderDir?.path)!) {
            debugPrint("_strips folder already exists... deleting all the files in it")
            do {
                let filePaths = try fileManager.contentsOfDirectory(
                    at: stripsFolderDir!,
                    includingPropertiesForKeys: [URLResourceKey.nameKey],
                    options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles
                )
                for filePath in filePaths {
//                    debugPrint(filePath)
                    try fileManager.removeItem(at: filePath)
                }
            } catch {
                debugPrint("Could not clear _strips folder: \(error)")
            }
            
            // otherwise try and create it
        } else {
            do {
                try individualImages.fileManager.createDirectory(at: stripsFolderDir!, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print(error)
            }
        }
        
        // do the cropping asyncronously
        // create custom queue on userInitiated thread
        let cropQueue = DispatchQueue(label: "pics.rmpb.cropqueue", qos: .userInitiated, attributes: .concurrent)
        
        // create dispatch group to control subsequent action triggers
        let cropGroup = DispatchGroup()
        
        print(Date())
        print("cropping started")
        
        // crop strips
        for photoStripImage in photoStripImages.allImages {
            
            // create task to be queued
            let cropTask = DispatchWorkItem {
                // get the URL to the strip
                let photoStripImageURL = photoStripImage.fileURL
                
                // Create a CGIImageSource reference by loading the image URL filepath
                let loadRef = CGImageSourceCreateWithURL(photoStripImageURL! as CFURL, nil)
                
                // load the image from the reference
                let imageRef = CGImageSourceCreateImageAtIndex(loadRef!, 0, nil)
                
                //            println("\(CGImageGetWidth(imageRef)), \(CGImageGetHeight(imageRef))")
                
                // crop the image
                let cropRect = NSMakeRect(CGFloat(crop.left*2), CGFloat(0), CGFloat((crop.right-crop.left)*2), 1844)
                let croppedImage = imageRef?.cropping(to: cropRect)
                
                //            println("\(CGImageGetWidth(croppedImage)), \(CGImageGetHeight(croppedImage))")
                
                // save the image to the strips folder
                let imageDest = stripsFolderDir?.appendingPathComponent(photoStripImage.fileName)
                
                // update the fileURL to the strips directory
                photoStripImage.fileURL = imageDest
                //                print(photoStripImage.fileURL.absoluteString)
                
                //            println(imageDest)
                
                let destination = CGImageDestinationCreateWithURL(imageDest! as CFURL, kUTTypeJPEG, 1, nil)
                CGImageDestinationAddImage(destination!, croppedImage!, nil)
                if CGImageDestinationFinalize(destination!) {
                    photoStripImage.fileState = "Cropped"
                } else {
                    photoStripImage.fileState = "Crop Failed"
                }
                
                // remove this item from the stack
                cropGroup.leave()
                
            } // end cropTask closure
            
            // add this task to the stack
            cropGroup.enter()

            // do the task
            cropQueue.async(execute: cropTask)
            
            // update the view on the main thread
            cropTask.notify(queue: .main) {
                self.photoStripImageTable.reloadData()
            }
        }
        
        cropGroup.notify(queue: .main){
            print(Date())
            print("cropping done! starting upload...")
            self.uploadImages()
        }
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.eventDatePicker.dateValue = Date()
        self.statusLabel.stringValue = "Status: Ready"
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    
    private func uploadImages() {
        
        // set max concurrent operations
        pendingOperations.opQueue.maxConcurrentOperationCount = 10
    
        
        //upload images
        for individualImage in individualImages.allImages {
            
            startUploadForRecord(individualImage, tableView: individualImageTable)
        }
        
        //upload strips
        for photoStripImage in photoStripImages.allImages {
            
            startUploadForRecord(photoStripImage, tableView: photoStripImageTable)
        }
        
    }
    
    
    private func startUploadForRecord(_ imageDetails: Image, tableView: NSTableView){
        // send the Image to flickrUploader
        let uploader = FlickrUploader(image: imageDetails, tableView: tableView)
        
        // add the operation to the list of pending operations
        // pendingOperations.uploadsInProgress[imageDetails.index] = uploader
        
        // add the operation to the operation queue
        pendingOperations.opQueue.addOperation(uploader)

        // update the image state
        imageDetails.fileState = "Queued"
        
        DispatchQueue.main.async(execute: {
            tableView.reloadData()
        })
        
        // after the operation is complete
        uploader.completionBlock = {
            // update the image state
            imageDetails.fileState = "Uploaded"

            DispatchQueue.main.async(execute: {
                tableView.reloadData()
            })

            if pendingOperations.opQueue.operationCount == 0 {
                print(Date())
                print ("upload complete! adding to Photosets...")
                self.createPhotosets()
            }
        }
    }
    
    private func createPhotosets(){
        startCreatePhotosets(individualImages)
        startCreatePhotosets(photoStripImages)
    }
    
    
    private func startCreatePhotosets(_ photoset: TableHelper) {
        
        let createPhotoset = FlickrCreatePhotoset(images: photoset)
        
        // add the operation to the operation queue
        pendingOperations.opQueue.addOperation(createPhotoset)
        
        // after the operation is complete
        createPhotoset.completionBlock = {
//            print ("photoset created")
            
            var addToPhotoset = [Int:FlickrAddToPhotoset]()
            for image in photoset.allImages {
                
                // for all images, except the first one, which was used to create the photoset
                if image.index != photoset.allImages[0].index {
                    addToPhotoset[image.index] = FlickrAddToPhotoset(image: image, photosetID: photoset.flickrPhotoset)
                    
                    // add the operation to the queue
                    pendingOperations.opQueue.addOperation(addToPhotoset[image.index]!)
                    
                    // after the operation is complete
                    addToPhotoset[image.index]!.completionBlock = {
                        DispatchQueue.main.async(execute: {
                            self.photoStripImageTable.reloadData()
                            self.individualImageTable.reloadData()
                        })
                        if pendingOperations.opQueue.operationCount == 0 {
                            print(Date())
                            print ("add to photosets complete! creating XML...")
                            self.createXML()
                        }
                    }
                }
            }
        }
    }
 
    private func createXML(){
        
        let xmlObj = Xml()
        xml = xmlObj.createXML(self.mainDir!)
        
        print(Date())
        print("XML created! creating event...")
        self.createEvent()
        
    }

    private func createEvent(){
    
        // create an alert
        let alert = NSAlert()

        // this flag will be set to false if any of the updates fail
        var updated = true
        
        // these calls happen asyncronously, so create a DispatchGroup and add this to the stack
        let eventUpdateGroup = DispatchGroup()
        eventUpdateGroup.enter()
//        print("create event entered group")
        
        // add two years to the event date to get the expiration date
        let components: DateComponents = DateComponents()
        (components as NSDateComponents).setValue(2, forComponent: NSCalendar.Unit.year)
        let eventExpiration = (Calendar.current as NSCalendar).date(byAdding: components, to: self.eventDatePicker.dateValue, options: NSCalendar.Options(rawValue: 0))
        
        // create the event
        // this adds a record to the db which sets title, password, and expiration date
        // all subsequent updates use the eventTitle as the key
        let eventTitle = self.imageFolderLabel.stringValue
        RMPB().createEvent(eventTitle, eventPassword: self.eventPasswordLabel.stringValue, eventExpiration: eventExpiration!, completionHandler: { success in
            
            // the completion handler ensures the event is created before calling any updates
            if success {
                
                eventUpdateGroup.enter()
//                print("update 1 entered group")
                // add photoset id for strips - flickr_id_strips
                RMPB().updateEvent(eventTitle, field: "flickr_id_strips", value: photoStripImages.flickrPhotoset, completionHandler: { success in
                    if !success { updated = false }
                    eventUpdateGroup.leave()
//                    print("update 1 left group")
                })
                
                eventUpdateGroup.enter()
//                print("update 2 entered group")
                // add photoset id for individual images - flickr_id_individuals
                RMPB().updateEvent(eventTitle, field: "flickr_id_individuals", value: individualImages.flickrPhotoset, completionHandler: { success in
                    if !success { updated = false }
                    eventUpdateGroup.leave()
//                    print("update 2 left group")
                })

                
                eventUpdateGroup.enter()
//                print("update 3 entered group")
                // add badge image - image
                RMPB().updateEvent(eventTitle, field: "image", value: eventBadgeURL!.lastPathComponent, badge: eventBadgeURL!, completionHandler: { success in
                    if !success { updated = false }
                    eventUpdateGroup.leave()
//                    print("update 3 left group")
                })

                
                eventUpdateGroup.enter()
//                print("update 4 entered group")
                // add xml file - photoXML
                RMPB().updateEvent(eventTitle, field: "photoXML", value: self.xml, completionHandler: { success in
                    if !success { updated = false }
                    eventUpdateGroup.leave()
//                    print("update 4 left group")
                })
                
            } else {
                updated = false
            }
            
            // remove from the stack
            // this is done whether or not it was successful
            eventUpdateGroup.leave()
//            print("create event left group")
        })

        eventUpdateGroup.notify(queue: .main){
            print(Date())
            print("event created!")
            
            // if everything worked, display a success alert
            if updated {
                alert.messageText = "Success!"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Dismiss")
                alert.informativeText = "Everything worked!  You can quit with cmd+Q."
            } else {
                alert.messageText = "Problem!"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Dismiss")
                alert.informativeText = "Something went wrong with event creation! You should check it out and then try again. You can quit with cmd+Q."
            }
            alert.beginSheetModal(for: self.window, completionHandler: nil)

        }
        
    }
    
    
    // -----------------------------------------------
    // NSTableViewDataSource Delegate methods
    // -----------------------------------------------
    
    func numberOfRows(in aTableView: NSTableView) -> Int {
        if aTableView.identifier == "individualImages" {
            return individualImages.numberOfRowsInTableView(aTableView)
        } else {
            return photoStripImages.numberOfRowsInTableView(aTableView)
        }
    }
    
    func tableView(_ aTableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if aTableView.identifier == "individualImages" {
            return individualImages.tableView(aTableView, objectValueForTableColumn: tableColumn, row: row)
        } else {
            return photoStripImages.tableView(aTableView, objectValueForTableColumn: tableColumn, row: row)
        }
    }
    
}









