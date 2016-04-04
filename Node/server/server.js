var packageVersion = require('./../package.json').version;
console.log("packageVersion :: " + packageVersion);

var loopback = require('loopback');
var boot = require('loopback-boot');

var app = module.exports = loopback();
var bodyParser = require('body-parser');

var request = require('request');
app.use(bodyParser.json());
try {
    //Getting VCAP service information from Bluemix Application
    var vcap = JSON.parse(process.env.VCAP_SERVICES);
    //Push Secret from VCAP
    var pushSecret = vcap.imfpush[0].credentials.appSecret;
    //Push Admin URL from VCAP
    var pushAdminURL = vcap.imfpush[0].credentials.admin_url;
    //Splitting pushAdminURL to get pushAppId
    var pushAdminURLArray = pushAdminURL.split('=');
    //Get Push Application ID after splitting admin URL
    var pushAppId = pushAdminURLArray[1];
    //Splitting Array further to get Application Region
    var pushRegion = pushAdminURLArray[0].split('.');
    //Application Region
    pushRegion = pushRegion[1];
}catch (e) {
    console.error("Error encountered while obtaining Bluemix service credentials." +
                  " Make certain that the Mobile Client Access and Bluemix Push Notification service are bound to this application." +
                  " Error: " + e);
}

// ------------ Protecting mobile backend with Mobile Client Access start -----------------

// Load passport (http://passportjs.org)
var passport = require('passport');

// Get the MCA passport strategy to use
var MCABackendStrategy = require('bms-mca-token-validation-strategy').MCABackendStrategy;

// Tell passport to use the MCA strategy
passport.use(new MCABackendStrategy())

// Tell application to use passport
app.use(passport.initialize());

// Protect DELETE endpoint so it can only be accessed by HelloTodo mobile samples
app.delete('/api/Items/:id', passport.authenticate('mca-backend-strategy', {session: false}));

// Protect /protected endpoint which is used in Getting Started with Bluemix Mobile Services tutorials
app.get('/protected', passport.authenticate('mca-backend-strategy', {session: false}), function(req, res){
	res.send("Hello, this is a protected resouce of the mobile backend application!");
});

//Function to send a test push message to a requesting device
app.post('/sendPushToDevice', function(req, res){
         console.log("Attempting to send Push Notification to requested device");
         //Outputting the pushDeviceId that is sent from the device
         console.log("Here is the push device ID: " + req.body.pushDeviceId);
         //Creating a push notification if the device sent a valid pushDeviceId
         if (req.body.pushDeviceId){
         var jsonObject =
         {
         "message": {
         //The message we will send in the push notification
         "alert": "Hello From Node. Here is your push message: " + req.body.pushText
         },
         "target":{
         //Targeting the requesting device
         "deviceIds":[req.body.pushDeviceId]
         }
         };
         //Outputting the push URL we are uing to send a push notification for verification
         console.log("Here is the push URL we are sending a request to: " + "https://mobile." + pushRegion + ".bluemix.net/imfpush/v1/apps/" + pushAppId + "/messages");
         request({
                 //URL we are using to send push notification. Pulling in region and appid from VCAP
                 url: "https://mobile." + pushRegion + ".bluemix.net/imfpush/v1/apps/" + pushAppId + "/messages",
                 method: "POST",
                 json: true,
                 body: jsonObject,
                 headers: {
                 //Including the push secret as a header. We obtained this from VCAP
                 'appSecret':pushSecret
                 }
                 }, function (error, response, body){
                 //Handle successful request when response code was valid 202 and no error is present
                 if(!error && response.statusCode == 202){
                 console.log(response.statusCode, "Notified device " + req.body.pushDeviceId + " successfully with following message: " + jsonObject.message.alert );
                 res.status(response.statusCode).send({result: "Sent notification to registered device.", response: body});
                 //Handle error
                 }else if(error){
                 console.log("Error from Push Service: " + error);
                 res.status(response.statusCode).send({reason: "An error occurred while sending the Push notification.", error: error});
                 //Unkown Error. Print out valuable information for debug
                 }else{
                 console.log("An unknown problem occurred, printing response. Please verify your app secret, appId and/or pushDeviceId");
                 console.log(response);
                 console.log(response.statusCode);
                 res.status(response.statusCode).send({reason: "A problem occurred while sending the Push notification. Please verify your app secret and/or pushDeviceId.", message: body});
                 }
                 });
         }
         else{
         console.log("Device " + req.body.pushDeviceId + " is not registered. Cannot send push message to device");
         }
         
         });

// ------------ Protecting backend APIs with Mobile Client Access end -----------------

app.start = function () {
	// start the web server
	return app.listen(function () {
		app.emit('started');
		var baseUrl = app.get('url').replace(/\/$/, '');
		console.log('Web server listening at: %s', baseUrl);
		var componentExplorer = app.get('loopback-component-explorer');
		if (componentExplorer) {
			console.log('Browse your REST API at %s%s', baseUrl, componentExplorer.mountPath);
		}
	});
};

// Bootstrap the application, configure models, datasources and middleware.
// Sub-apps like REST API are mounted via boot scripts.
boot(app, __dirname, function (err) {
	if (err) throw err;
	if (require.main === module)
		app.start();
});

