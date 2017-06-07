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
    
    var xml: String = String()
    var mainDir: URL?

    
    // Create a shared AppDelegate (not currently used)
    //    class var sharedInstance : AppDelegate {
    //        struct Static {
    //            static let instance : AppDelegate = AppDelegate()
    //        }
    //        return Static.instance
    //    }
    
    // Mark: UI methods
    
    // Select the main image folder when the button is clicked
    @IBAction func selectImageFolder(_ sender: AnyObject) {
        
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
            }
        })
        
    }
    
    @IBAction func selectEventBadge(_ sender: AnyObject) {
        if let badgeURL = NSOpenPanel().selectUrl {
            eventBadge.image = NSImage(contentsOf: badgeURL as URL)
            eventBadgeURL = badgeURL
            print(eventBadgeURL!)
        } else {
            print("file selection was canceled")
        }
    }
    
    @IBAction func setCropParams(_ sender: AnyObject) {
        if imageCropperController == nil {
            imageCropperController = ImageCropperController.init(windowNibName: "ImageCropperController")
        }
        imageCropperController!.showWindow(nil)
    }
    
    @IBAction func beginProcess(_ sender: NSButton) {
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
        
        // crop strips
        for photoStripImage in photoStripImages.allImages {
            
            
            //do this asyncronously
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
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
                    // update the view on the main thread
                    DispatchQueue.main.async{
                        self.photoStripImageTable.reloadData()
                    }
                } else {
                    photoStripImage.fileState = "Crop Failed"
                    // update the view on the main thread
                    DispatchQueue.main.async{
                        self.photoStripImageTable.reloadData()
                    }
                }
            } // end async closure
        }
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.eventDatePicker.dateValue = Date()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
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
    
    
    @IBAction func uploadImages(_ sender: AnyObject) {
        
        //upload images
        for individualImage in individualImages.allImages {
            
            startUploadForRecord(individualImage, tableView: individualImageTable)
        }
        
        //upload strips
        for photoStripImage in photoStripImages.allImages {
            
            startUploadForRecord(photoStripImage, tableView: photoStripImageTable)
        }
        
        //        pendingOperations.
        
    }
    
    
    func startUploadForRecord(_ imageDetails: Image, tableView: NSTableView){
        // send the Image to flickrUploader
        let uploader = FlickrUploader(image: imageDetails, tableView: tableView)
        
        // set max concurrent operations
        pendingOperations.opQueue.maxConcurrentOperationCount = 10
        
        // add the operation to the list of pending operations
        //        pendingOperations.uploadsInProgress[imageDetails.index] = uploader
        
        // add the operation to the operation queue
        pendingOperations.opQueue.addOperation(uploader)
        
        DispatchQueue.main.async(execute: {
            // update the image state
            imageDetails.fileState = "Queued"
            tableView.reloadData()
        })
        
        // after the operation is complete
        uploader.completionBlock = {
            DispatchQueue.main.async(execute: {
                // remove the operation from the list of pending operations
                //                pendingOperations.uploadsInProgress.removeValueForKey(imageDetails.index)
                
                
                // update the image state
                imageDetails.fileState = "Uploaded"
                tableView.reloadData()
            })
            if pendingOperations.opQueue.operationCount == 0 {
                print ("upload complete")
                self.createPhotosets()
            }
        }
    }
    
    func createPhotosets(){
        startCreatePhotosets(individualImages)
        startCreatePhotosets(photoStripImages)
    }
    
    
    func startCreatePhotosets(_ photoset: TableHelper) {
        
        let createPhotoset = FlickrCreatePhotoset(images: photoset)
        
        // add the operation to the operation queue
        pendingOperations.opQueue.maxConcurrentOperationCount = 10
        pendingOperations.opQueue.addOperation(createPhotoset)
        
        // after the operation is complete
        createPhotoset.completionBlock = {
            print ("photoset created")
            
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
                            print ("add to photosets complete")
                        }
                    }
                }
            }
        }
    }
    
    
    @IBAction func startCreateXML(_ sender: NSButton) {
        
        let xmlObj = Xml()
        xml = xmlObj.createXML(self.mainDir!)
        
        print("XML created")
        
    }
    
    @IBAction func createEvent(_ sender: NSButton) {
        
        // check to make sure there's a password
        // and if not, show an alert
        if self.eventPasswordLabel.stringValue == "" {
            let alert = NSAlert()
            alert.messageText = "Error!"
            alert.addButton(withTitle: "Dismiss")
            alert.informativeText = "You need to enter the event's password!"
            alert.beginSheetModal(for: self.window, completionHandler: nil)
        } else {
            
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
                    // add photoset id for strips - flickr_id_strips
                    RMPB().updateEvent(eventTitle, field: "flickr_id_strips", value: photoStripImages.flickrPhotoset)
                    
                    // add photoset id for individual images - flickr_id_individuals
                    RMPB().updateEvent(eventTitle, field: "flickr_id_individuals", value: individualImages.flickrPhotoset)
                    
                    // add badge image - image
                    RMPB().updateEvent(eventTitle, field: "image", value: eventBadgeURL!.lastPathComponent, badge: eventBadgeURL!)
                    
                    // add xml file - photoXML
                    RMPB().updateEvent(eventTitle, field: "photoXML", value: self.xml)
                    
                }
            })
            
            
        }
    }
}









