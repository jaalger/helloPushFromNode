# iOS helloPushFromNode Sample Application for Bluemix Mobile Services
---
This iOS helloPush sample contains a Swift project that you can use to learn more about the IBM Push Notification Service. It also provides custom Node.js code in order to send a push notification directly to a requesting device.  

Use the following steps to configure the helloPush sample for Objective-C:

1. [Download the helloPushFromNode sample](#download-the-hellopushfromnode-sample)
2. [Configure the mobile backend for your helloPushFromNode application](#configure-the-mobile-backend-for-your-hellopushfromnode-application)
3. [Deploy the custom Node code to your Bluemix environment](#deploy-the-custom-node-code-to-your-bluemix-environment)
4. [Configure the front end in the helloPushFromNode sample](#configure-the-front-end-in-the-hellopushfromnode-sample)
5. [Run the iOS app](#run-the-ios-app)

### Before you begin
Before you start, make sure you have the following:

- A [Bluemix](http://bluemix.net) account.
- APNs enabled push certificate (.p12 file) and the certificate password for your sandbox environment. For information about how to obtain a p.12 certificate, see the [configuring credentials for a notification provider](https://www.ng.bluemix.net/docs/services/mobilepush/index.html#push_provider) section in the Push documentation.

### Download the helloPushFromNode sample
Clone the sample from Github with the following command:

```git clone https://github.com/jaalger/helloPushFromNode```

### Configure the mobile backend for your helloPushFromNode application
Before you can run the helloPush application, you must set up an app on Bluemix.  The following procedure shows you how to create a MobileFirst Services Starter application. A Node.js runtime environment is created so that you can provide server-side functions, such as resource URIs and static files. The Cloudant®NoSQL DB, IBM Push Notifications, and Mobile Client Access services are then added to the app. For this sample we will mostly be using Node.js and IBM Push Notification, but it is recommended to use the boilerplate so you can expand on the application.

Create a mobile backend in the  Bluemix dashboard:

1.	In the **Boilerplates** section of the Bluemix catalog, click **MobileFirst Services Starter**.
2.	Enter a name and host for your mobile backend and click **Create**.
3.	Click **Finish**.

Configure Push Notification service:

1.	In the IBM Push Notifications Dashboard, go to the **Configuration** tab to configure your Push Notification Service.  
2.  In the Apple Push Certificate section, select the Sandbox environment
3.  Upload a valid APNs enabled push certificate (.p12 file), then enter the password associated with the certificate.

### Deploy the custom Node code to your Bluemix environment
The helloPushFromNode sample application requires custom code to be deployed to the Node.js application running on Bluemix. This code contains a function that handles sending push notifications to requesting devices when invoked from the client side application.
Follow the required steps to deploy the custom Node.js code. You can find the Node resources in the helloPushFromNode/Node directory:

1. Edit `manifest.yml` file. Change the `host` and `name` properties to match the app name you assigned when creating the Bluemix MobileFirst boilerplate app. 
2. After logging in to Bluemix using the command `cf login -a https://api.{region}.bluemix.net` (where region is either ng, eu-gb, or au-syd) navigate to the NodeJS directory. Run the `cf push {your_Bluemix_app_name}` command to deploy your application to Bluemix which will bind the custom Node.js code to the Mobile Client Access service instance and start the app.
3. If done correctly, you should now have the updated Node.js app running in your Bluemix environment. 
4. Your Bluemix application is now available at: `https//{hostname}.{region}.mybluemix.net`

### Configure the front end in the helloPushFromNode sample
1. In a terminal, navigate to the `helloPushFromNode` directory where the project was cloned

Swift:

1. Navigate to the `helloPushFromNode` folder
2. If the CocoapPods client is not installed, install it using the following command: `sudo gem install cocoapods`
3. If the CocoaPods repository is not configured, configure it using the following command: `pod setup`
4. Run the `pod install` command to download and install the required dependencies.
5. Open the Xcode workspace: `open helloPushFromNode.xcworkspace`. From now on, open the xcworkspace file since it contains all the dependencies and configuration.
6. Make sure you set your Bundle Identidier in the `Info.plist` to match the configured certificate you have deployed to your Bluemix environment. 
7. Open the `Settings.plist` and add the corresponding **bluemixAppGUID**,
**bluemixAppRoute**, and **bluemixRegion**. You can find the bluemixAppGUID and bluemixAppRoute under the **mobile options** section in your Bluemix Dashboard. For your bluemixAppRoute it is recommended to use https protocol to hanlde the new requirements with Application Transport Securtiy (ATS). The bluemixRegion has the following options:

US: .ng.bluemix.net     
London: .eu-gb.bluemix.net      
Sydney: .au-syd.bluemix.net     

The helloPushFromNode application will use these configuration values in order to initialize your application agaist your Bluemix environment in the `AppDelegate.swift`. 

### Run the iOS app
For push notifications to work successfully, you must run the helloPushFromNode sample on a physical iOS device. You will also need a valid APNs enabled bundle id, provisioning profile, and development certificate.

When you run the application, you will see a single view application with a text box to enter message text, a "Register for Push" button, and a "Send Push From Node" button. You will first need to click the "Register for Push" button in order to  attempt to register the device and application to the Push Notification Service. The app uses an alert to display the registration status (successful or failed). On a successful registration the client side application saves the pushDeviceID that was assigned to the device from the Push Notification service. This is accomplished in the `AppDelegate.swift`:

```obj-c
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
  ```
  
After the device is successfully registered you can enter any text you wish to recieve in the text box and click the "Send Push From Node" button. A REST request will be called to the custom code (/sendPushFromNode) deployed on your Bluemix application. This is accomplished in the `ViewController.swift` in the `sendPushFromNode` function. The application uses the pushDeviceID that we saved after registration in order to make a request to the push notification only to the requesting device. If configured correctly, a push notification will be recieved on the device and an alert will be shown with the message text that was input into the text box. 


**Note:** This application runs on the latest version of XCode (7.0). The application has been updated to set Enable Bitcode to No in the build-settings as a workaround for the these settings introduced in iOS 9. For more info please see the following blog entry:

[Connect Your iOS 9 App to Bluemix](https://developer.ibm.com/bluemix/2015/09/16/connect-your-ios-9-app-to-bluemix/)

### License
This package contains sample code provided in source code form. The samples are licensed under the under the Apache License, Version 2.0 (the "License"). You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 and may also view the license in the license.txt file within this package. Also see the notices.txt file within this package for additional notices.
