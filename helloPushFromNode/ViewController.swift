//
//  ViewController.swift
//  helloPushFromNode
//
//  Created by Joshua Alger on 3/31/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import BMSCore
import BMSPush

class ViewController: UIViewController,  UITextFieldDelegate {

    @IBOutlet weak var pushRegistration: UIButton!
    @IBOutlet weak var sendPushFromNode: UIButton!
    @IBOutlet weak var pushText: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //Check for current Push Registration
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func registerForPush(sender: AnyObject) {
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()

    }
    @IBAction func sendPushFromNode(sender: AnyObject) {
        //Setting pushDeviceID that we previously recieved from Blumix Push Service after registration
        let pushDeviceID = NSUserDefaults.standardUserDefaults().stringForKey("pushDeviceID")
        //Getting boolean value of native Push Registration status
        let registrationStatus = UIApplication.sharedApplication().isRegisteredForRemoteNotifications()
        //Checking to see if device is registered to recieve Push Notifications before sending request to Node
        if(registrationStatus && pushDeviceID != nil){
            
            //Setting requestPath to our sendPushToDevice path on our Node application
            let requestPath =  BMSClient.sharedInstance.bluemixAppRoute! + "/sendPushToDevice"
            //Build an HTTP POST request ot our Node app to the getWaitTimes function
            let request = Request(url:requestPath, method: HttpMethod.POST);
            var pushMessageText = pushText.text!
            //If the text box is empty add corresponding text
            if(pushMessageText.isEmpty){
                pushMessageText = "TEXT BOX WAS EMPTY"
            }
            //Creating a JSON Dictionary to send pushDeviceId and pushText to the Node server
            let jsonDict: [NSObject : AnyObject] = [
            "pushDeviceId" : pushDeviceID!,
            "pushText" : pushMessageText
            ]
            do{
                //Converting the JSON Dictionary to NSData to create the body of the REST request
                let data: NSData = try NSJSONSerialization.dataWithJSONObject(jsonDict, options:NSJSONWritingOptions.PrettyPrinted)
                //Adding appropriate headers
                request.headers = ["Content-Type":"application/json"]
                //Sending the REST Request to our Node instance
                request.sendData(data, withCompletionHandler: { (response, error) -> Void in
                if (nil != error){
                    NSLog("Error :: %@", error!.description)
                } else {
                    NSLog("Response :: %@", response!.responseText!)
                }
                })
            }catch{
                print("Error creating REST request to send Push Notification")
                //Show an alert error message
                showAlert("Error", message: "Error creating REST request to send Push Notification")
            }
        }
        else{
            //Print error showing registration status
            print("Error sending Push Notification due to configuration issue. Push Registration Status is currently: " + String(registrationStatus))
            //Show an alert error message
            showAlert("Error", message: "Error sending Push Notification due to configuration issue. Push Registration Status is currently: " + String(registrationStatus))
            //If the pushDeviceID is nil print corresponding debug message
            if(pushDeviceID == nil){
                    print("PushDeviceID is currently nil. Please make sure you have registered the device successfully against your Bluemix Push Notification Service")
            }
        }
    }
    
    //Allow the keyboard to disappear when the return key is hit
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    //Function used to show an alert
    func showAlert (title:NSString , message:NSString){
        // create the alert
        dispatch_async(dispatch_get_main_queue(), {
            let alert = UIAlertController.init(title: title as String, message: message as String, preferredStyle: UIAlertControllerStyle.Alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            // show the alert
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
}
