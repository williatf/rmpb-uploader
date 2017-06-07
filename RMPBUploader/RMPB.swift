//
//  RMPB.swift
//  RMPBUploader
//
//  Created by Todd Williams on 6/18/16.
//  Copyright © 2016 Todd Williams. All rights reserved.
//

import Foundation
import Alamofire

class RMPB {
    
    let rmpbURL = "http://www.rmpb.net/admin/"
    
    func createEvent(_ eventTitle: String, eventPassword: String, eventExpiration: Date, completionHandler: @escaping (_ success:Bool)->()) {
        
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
        let endpoint = "uploadr_add.php"
        
//        print(eventExpiration)
        
        /** 
         POST should include params:
            'event_title'
            'event_password'
            'event_expiration'
        **/
    
        var params = Dictionary<String, String>()
        params["event_title"] = eventTitle
        params["event_password"] = eventPassword
        params["event_expiration"] = dateFormatter.string(from: eventExpiration)
        
        Alamofire.request(rmpbURL + endpoint, method: .post, parameters: params)
            .validate()
            .responseString { response in
                debugPrint("Create Event Response:")
                debugPrint(response.result)
                completionHandler(true)
            }
        
    }
    
    func updateEvent(_ eventTitle: String, field: String, value: String) {
        /**
         POST should include params:
         'event_title'
         'field'
         'value'
         **/
        
        let endpoint = "uploadr_edit.php"
        
        var params = Dictionary<String, String>()
        params["event_title"] = eventTitle
        params["field"] = field
        params["value"] = value
        
        Alamofire.request(rmpbURL + endpoint, method: .post, parameters: params)
            .validate()
            .responseString { response in
                debugPrint(response)
            }

    }
    
    func updateEvent(_ eventTitle: String, field: String, value: String, badge: URL) {
        /**
         POST should include params:
         'event_title'
         'field'
         'value'
         'badge' - as a file
         **/
        
        let endpoint = "uploadr_edit.php"
        
        var params = Dictionary<String, String>()
        params["event_title"] = eventTitle
        params["field"] = field
        params["value"] = value
        

        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                for (param, value) in params {
                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: param)
                }
                multipartFormData.append(badge, withName: "badge")
            },
            to: rmpbURL + endpoint,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseString  { response in
                        debugPrint(response)
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            }
        )
    }
}
