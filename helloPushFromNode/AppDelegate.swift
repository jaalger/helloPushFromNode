//
//  AppDelegate.swift
//  helloPushFromNode
//
//  Created by Joshua Alger on 3/31/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import BMSCore
import BMSPush
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        //Reading Settings.plist file for configuration values
        let configurationPath = NSBundle.mainBundle().pathForResource("Settings", ofType: "plist")
        let dictionary = NSDictionary(contentsOfFile: configurationPath!)
        let applicationRoute = dictionary!.valueForKey("bluemixAppRoute") as? String
        let applicationID = dictionary!.valueForKey("bluemixAppGUID") as? String
        let applicationRegion = dictionary!.valueForKey("bluemixRegion") as? String
        
        //Checking to make sure the values in Settings.plist are not empty
        if applicationRoute == "" || applicationID == "" || applicationRegion == ""{
            NSLog("Please make sure you have entered values for your bluemixAppRoute, bluemixAppGUID, and bluemixRegion in the Settings.plist file")
        }
        else{
            //Initialize Bluemix Client
            BMSClient.sharedInstance.initializeWithBluemixAppRoute(applicationRoute, bluemixAppGUID: applicationID, bluemixRegion: applicationRegion!)
            BMSClient.sharedInstance.defaultRequestTimeout = 10.0 //seconds
        }

        return true
    }
    
    //Making calls to register the application for Push Notifications
    func registerForPush () {
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    func application (application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData){
        let push =  BMSPushClient.sharedInstance
        //Registering Device for Push Notifications
        push.registerDeviceToken(deviceToken) { (response, statusCode, error) -> Void in
            //Handle successful registration
            if error.isEmpty {
                print( "Response during device registration : \(response)")
                print( "status code during device registration : \(statusCode)")
                //Obtain the pushDeviceID from the Push Notification service
                let pushDeviceId = BMSClient.sharedInstance.authorizationManager.deviceIdentity.id
                //Save the pushDeviceID locally
                NSUserDefaults.standardUserDefaults().setValue(pushDeviceId, forKey: "pushDeviceID")
                self.showAlert("Push Notification Registration", message: "Successfully registered for Push Notifications")
                }
            else{
                print( "Error during device registration \(error) ")
                self.showAlert("Push Notification Registration", message: "Failed to register for Push Notifications. Response: " + response)
                }
        }
    }
    //Called if unable to register for APNS.
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        let message:NSString = "Error registering for push notifications: "+error.description
        self.showAlert("Registering for notifications", message: message)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        //Get the message text from the Push Notification
        let payLoad = ((((userInfo as NSDictionary).valueForKey("aps") as! NSDictionary).valueForKey("alert") as! NSDictionary).valueForKey("body") as! NSString)
        //Show message text to user in alert
        self.showAlert("Recieved Push Notification", message: payLoad)
        let push =  BMSPushClient.sharedInstance
        push.application(UIApplication.sharedApplication(), didReceiveRemoteNotification: userInfo)
        
    }
    
    func showAlert (title:NSString , message:NSString){
        // create the alert
        dispatch_async(dispatch_get_main_queue(), {
            // code here
     
        let alert = UIAlertController.init(title: title as String, message: message as String, preferredStyle: UIAlertControllerStyle.Alert)
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        // show the alert
        self.window!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
               })
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

