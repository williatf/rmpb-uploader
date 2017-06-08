//
//  Flickr.swift
//  RMPBUploader
//
//  Created by Todd Williams on 6/13/16.
//  Copyright © 2016 Todd Williams. All rights reserved.
//

import Cocoa
import Alamofire
import AEXML

let flickr = Flicker()

struct Flicker {
    
    //Flickr API info
    var APIKey: String
    var SharedSecret: String
    var AuthToken: String
    var AuthSecret: String
    let RESTAPI       = "https://api.flickr.com/services/rest/"
    let UploadAPI     = "https://api.flickr.com/services/upload/"

    // initialize!
    init(){
        
        let prefs = UserDefaults.standard
        
        // read keys from UserDefaults
        APIKey          = prefs.object(forKey: "RMPB_apiKey") as! String
        SharedSecret    = prefs.object(forKey: "RMPB_sharedSecret") as! String
        AuthToken       = prefs.object(forKey: "RMPB_authToken") as! String
        AuthSecret      = prefs.object(forKey: "RMPB_authSecret") as! String
    }
    
}

class FlickrUploader: ConcurrentOperation {
    
    
    /**
     
     Flickr requires all request to be signed.
     
     Request Signatures are HMAC-SHA1 encrypted strings.  HMAC-SHA1 requires a string and a key.
     
     string = "<method>&<requestURL>&<parameters sorted by name, seperated by &>" that has been URL encoded.
     
     e.g. "GET&https%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Frequest_token&oauth_callback%3Dhttp%253A%252F%252Fwww.example.com%26oauth_consumer_key%3D653e7a6ecc1d528c516cc8f92cf98611%26oauth_nonce%3D95613465%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1305586162%26oauth_version%3D1.0"
     
     key = "<SharedSecret>&<AuthSecret>"
     
     **/
    
   
    
    // add a constant reference to the image file related to the operation
    let image: Image
    let tableView: NSTableView
    
    // create a designated initializer allowing the photo record to be passed in
    init(image: Image, tableView: NSTableView) {
        self.image = image
        self.tableView = tableView
        super.init()
    }
    
    // override the main method in the NSOperation subclass to perform the work
    override func main() {
        
        var params = Dictionary<String, String>()
        params["oauth_nonce"] = randomNumber(8)
        params["oauth_timestamp"] = "\(Int(Date().timeIntervalSince1970))"
        params["oauth_consumer_key"] = flickr.APIKey
        params["oauth_signature_method"] = "HMAC-SHA1"
        params["oauth_version"] = "1.0"
        params["oauth_token"] = flickr.AuthToken
        params["tags"] = "auto-upload RMPBUploadr-Mac"
        params["is_public"] = "1"
        params["is_friend"] = "0"
        params["is_family"] = "0"
        params["title"] = image.fileURL.deletingPathExtension().lastPathComponent
        
        //sort the params by key
        let sortedParams = params.sorted { $0.0 < $1.0 }
        
        //generate base string
        let baseString = "POST&" + flickr.UploadAPI.escape() + "&"
        
        var paramString = ""
        var firstPass = true
        for (param, value) in sortedParams {
            if firstPass {
                paramString = param + "=" + value.escape()
                firstPass = false
            } else {
                paramString += "&" + param + "=" + value.escape()
            }
        }
        
        //url encode param string
        let urlEncodedBaseString = baseString + paramString.escape()
        
//        print(urlEncodedBaseString)
        
        // generate the signature
        let key = flickr.SharedSecret + "&" + flickr.AuthSecret
        
        let sha1Digest = urlEncodedBaseString.hmacsha1(key)
        let base64Encoded = sha1Digest.base64EncodedData(options: NSData.Base64EncodingOptions.lineLength64Characters)
        let oauth_signature = NSString(data: base64Encoded, encoding: String.Encoding.utf8.rawValue)! as String
        
        params["oauth_signature"] = oauth_signature
        
        // upload the image
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                            
                // import parameters
                for (param, value) in params {
                    // print(NSString(data: value.dataUsingEncoding(NSUTF8StringEncoding)!, encoding: NSUTF8StringEncoding))
                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: param)
                }
                            
                // import image to request
                do {
                    let imageData = try Data(contentsOf: self.image.fileURL)
                    multipartFormData.append(imageData, withName: "photo", fileName: self.image.fileURL.lastPathComponent, mimeType: "image/jpeg")
                } catch {
                    debugPrint("Error with imageData in FlickrUploader")
                }
                
            },

            to: flickr.UploadAPI,

            // once the encoding in complete, this closure is called
            encodingCompletion: { encodingResult in
                switch encodingResult {
                
                // if the encoding is successful, do this
                case .success(let upload, _, _):

                    // after the upload is complete, get the response string
                    upload.responseString { response in
                        do {
                            
                            // debugPrint("\(response.result.value)")
                            
                            // create an xml response object from the response
                            let xmlResponse = try AEXMLDocument(xml: response.data!)
                            
                            // grab the photoid from the response object
                            self.image.flickrPhotoid = xmlResponse.root["photoid"].string
                            
                        } catch {
                            print("\(error)")
                        }
                        
                        // mark the operation complete, so the next operation in the queue can start
                        self.completeOperation()
                    }
                    
                    // while the upload is in progress, update the filestate with the upload percentage
                    upload.uploadProgress { progress in
                        let progressStr = String(format:"%.0f %%", (progress.fractionCompleted) * 100)
                        self.image.fileState = progressStr
                        
                        // reload the UI from the main queue
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                        
                    }
                    
                case .failure(let encodingError):
                    print(encodingError)
                    self.cancel()
            }
        })
    }
    
    override func cancel(){
        super.cancel()
        self.completeOperation()
    }
    

}


class FlickrCreatePhotoset: ConcurrentOperation {
    
    let images: TableHelper
    
    init(images: TableHelper){
        self.images = images
        super.init()
    }
    
    override func main(){
        
        var params = Dictionary<String, String>()
        params["oauth_nonce"] = randomNumber(8)
        params["oauth_timestamp"] = "\(Int(Date().timeIntervalSince1970))"
        params["oauth_consumer_key"] = flickr.APIKey
        params["oauth_signature_method"] = "HMAC-SHA1"
        params["oauth_version"] = "1.0"
        params["oauth_token"] = flickr.AuthToken
//        params["title"] = "Test-" + randomNumber(8) // images.flickrPhotosetTitle
        params["title"] = images.flickrPhotosetTitle
        params["primary_photo_id"] = images.allImages[0].flickrPhotoid
        params["method"] = "flickr.photosets.create"
        
        //sort the params by key
        let sortedParams = params.sorted { $0.0 < $1.0 }
        
        //generate base string
        let baseString = "POST&" + flickr.RESTAPI.escape() + "&"
        
        var paramString = ""
        var firstPass = true
        for (param, value) in sortedParams {
            if firstPass {
                paramString = param + "=" + value.escape()
                firstPass = false
            } else {
                paramString += "&" + param + "=" + value.escape()
            }
        }
        
        //url encode param string
        let urlEncodedBaseString = baseString + paramString.escape()
        
//                print(urlEncodedBaseString)
        
        // generate the signature
        let key = flickr.SharedSecret + "&" + flickr.AuthSecret
        
        let sha1Digest = urlEncodedBaseString.hmacsha1(key)
        let base64Encoded = sha1Digest.base64EncodedData(options: NSData.Base64EncodingOptions.lineLength64Characters)
        let oauth_signature = NSString(data: base64Encoded, encoding: String.Encoding.utf8.rawValue)! as String
        
        params["oauth_signature"] = oauth_signature
        
        // make the POST request to Flickr
        Alamofire.request(flickr.RESTAPI, method: .post, parameters: params)
        .validate()
        .responseString { response in
            switch response.result {
            case .success:
                print("\(String(describing: response.result.value))")
                do {
                    
                    // create an xml response object from the response
                    let xmlResponse = try AEXMLDocument(xml: response.data!)
                    
                    // grab the photoid from the response object
                    self.images.flickrPhotoset = xmlResponse.root["photoset"].attributes["id"]!
                    self.images.allImages[0].fileState = "Photoset"
                    
                    self.completeOperation()
                    
                } catch {
                    print("\(error)")
                }

            case .failure(let error):
                print(error)
            }

        }
        
   
    }
    
    override func cancel(){
        super.cancel()
        self.completeOperation()
    }
    
}

class FlickrAddToPhotoset: ConcurrentOperation {
    
    
    let image: Image
    let photosetID: String
    
    init(image: Image, photosetID: String){
        self.image = image
        self.photosetID = photosetID
        super.init()
    }
    
    override func main(){

        var params = Dictionary<String, String>()
        params["oauth_nonce"] = randomNumber(8)
        params["oauth_timestamp"] = "\(Int(Date().timeIntervalSince1970))"
        params["oauth_consumer_key"] = flickr.APIKey
        params["oauth_signature_method"] = "HMAC-SHA1"
        params["oauth_version"] = "1.0"
        params["oauth_token"] = flickr.AuthToken
        params["photoset_id"] = photosetID
        params["photo_id"] = image.flickrPhotoid
        params["method"] = "flickr.photosets.addPhoto"

        //sort the params by key
        let sortedParams = params.sorted { $0.0 < $1.0 }
        
        //generate base string
        let baseString = "POST&" + flickr.RESTAPI.escape() + "&"
        
        var paramString = ""
        var firstPass = true
        for (param, value) in sortedParams {
            if firstPass {
                paramString = param + "=" + value.escape()
                firstPass = false
            } else {
                paramString += "&" + param + "=" + value.escape()
            }
        }
        
        //url encode param string
        let urlEncodedBaseString = baseString + paramString.escape()
        
        //        print(urlEncodedBaseString)
        
        // generate the signature
        let key = flickr.SharedSecret + "&" + flickr.AuthSecret
        
        let sha1Digest = urlEncodedBaseString.hmacsha1(key)
        let base64Encoded = sha1Digest.base64EncodedData(options: NSData.Base64EncodingOptions.lineLength64Characters)
        let oauth_signature = NSString(data: base64Encoded, encoding: String.Encoding.utf8.rawValue)! as String
        
        params["oauth_signature"] = oauth_signature
        
        // make the POST request to Flickr
        Alamofire.request(flickr.RESTAPI, method: .post, parameters: params)
            .validate()
            .responseString { response in
                switch response.result {
                case .success:
//                    print("\(response.result.value)")
                    do {
                        
                        // create an xml response object from the response
                        let xmlResponse = try AEXMLDocument(xml: response.data!)
                        
                        // grab the stat from the response object
                        if xmlResponse.root.attributes["stat"]! == "ok" {
                            self.image.fileState = "Photoset"
                        } else {
                            self.image.fileState = "! Photoset"
                        }
                        
                        self.completeOperation()
                        
                    } catch {
                        print("\(error)")
                    }
                case .failure(let error):
                    print(error)
                }
        }

        
    }
        
        override func cancel(){
            super.cancel()
            self.completeOperation()
        }
    
}

func randomNumber(_ length: Int) -> String {
    
    let allowedChars = "0123456789"
    let allowedCharsCount = UInt32(allowedChars.characters.count)
    var randomString = ""
    
    for _ in (0..<length) {
        let randomNum = Int(arc4random_uniform(allowedCharsCount))
        let newCharacter = allowedChars[allowedChars.characters.index(allowedChars.startIndex, offsetBy: randomNum)]
        randomString += String(newCharacter)
    }
    
    return randomString
}
