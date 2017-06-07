//
//  String.swift
//  RMPBUploader
//
//  Created by Todd Williams on 6/17/16.
//  Copyright © 2016 Todd Williams. All rights reserved.
//

import Foundation



extension String {
    
    func percentEncode() -> String {
        let percentEncoded = self  //.stringByReplacingOccurrencesOfString(" ", withString: "-")
        let disallowedChars = "`~!@#$^&*()=+[]\\{}|;':\",/<>? "
        return percentEncoded.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: disallowedChars).inverted)!
    }
    
    func escape() -> String {
        let escapedSymbols = "`!@#$^&*()=+[]\\{}|;':\",/<>?" as CFString
        let escaped: CFString = CFURLCreateStringByAddingPercentEscapes(nil, self as CFString, nil, escapedSymbols, CFStringBuiltInEncodings.UTF8.rawValue)
        return escaped as String
    }
    
    func hmacsha1(_ key: String) -> Data {
        
        let dataToDigest = self.data(using: String.Encoding.utf8)
        let secretKey = key.data(using: String.Encoding.utf8)
        
        let digestLength = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLength)
        
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), (secretKey! as NSData).bytes, secretKey!.count, (dataToDigest! as NSData).bytes, dataToDigest!.count, result)
        
        return Data(bytes: UnsafePointer<UInt8>(result), count: digestLength)
        
    }
    
}
