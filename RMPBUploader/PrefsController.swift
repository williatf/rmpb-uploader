//
//  PrefsController.swift
//  
//
//  Created by Todd Williams on 6/7/17.
//
//

import Cocoa

class PrefsController: NSWindowController {

    @IBOutlet weak var apiKeyField: NSTextField!
    @IBOutlet weak var sharedSecretField: NSTextField!
    @IBOutlet weak var authTokenField: NSTextField!
    @IBOutlet weak var authSecretField: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        let prefs = UserDefaults.standard
        
        var apiKey          = prefs.object(forKey: "RMPB_apiKey")
        var sharedSecret    = prefs.object(forKey: "RMPB_sharedSecret")
        var authToken       = prefs.object(forKey: "RMPB_authToken")
        var authSecret      = prefs.object(forKey: "RMPB_authSecret")
        
        if apiKey == nil {
            apiKey = "Not Set"
            prefs.set(apiKey, forKey: "RMPB_apiKey")
        }
        
        if sharedSecret == nil {
            sharedSecret = "Not Set"
            prefs.set(sharedSecret, forKey: "RMPB_sharedSecret")
        }
        
        if authToken == nil {
            authToken = "Not Set"
            prefs.set(authToken, forKey: "RMPB_authToken")
        }
        
        if authSecret == nil {
            authSecret = "Not Set"
            prefs.set(authSecret, forKey: "RMPB_authSecret")
        }
        
        apiKeyField.stringValue         = apiKey! as! String
        sharedSecretField.stringValue   = sharedSecret! as! String
        authTokenField.stringValue      = authToken! as! String
        authSecretField.stringValue     = authSecret! as! String
        
        
    }
    
    @IBAction func updatePrefs(_ sender: NSButton) {
        
        let prefs = UserDefaults.standard
        
        let apiKey          = apiKeyField.stringValue
        let sharedSecret    = sharedSecretField.stringValue
        let authToken       = authTokenField.stringValue
        let authSecret      = authSecretField.stringValue
        
        prefs.set(apiKey, forKey: "RMPB_apiKey" )
        prefs.set(sharedSecret, forKey: "RMPB_sharedSecret" )
        prefs.set(authToken, forKey: "RMPB_authToken" )
        prefs.set(authSecret, forKey: "RMPB_authSecret" )
        
        prefs.synchronize()

        // close the window
        self.close()
        
    }
    
    @IBAction func cancelPrefs(_ sender: NSButton) {
        
        // close the window without saving
        self.close()
    }
}
