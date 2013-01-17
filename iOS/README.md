# AdTonik Mobile SDK

The AdTonik Mobile SDK currently implements our audio automated content recognition technology. Future functionality
will include a mobile ad sdk client which can act as a mediation layer as well as directly pull ads from the AdTonik ad
server.

## API Documentation

You can view the API documents at [http://dev.adtonik.net/docs](http://adtonik.net/docs)

## Integration

Go to [http://control.adtonik.net](http://control.adtonik.net) to register your application and generate an App ID
and App Secret which will be used in your ADTAudioACRDelegate.

See the examples/ directory to get an idea of how simple it is to integrate our SDK in an existing application.

### DemoApp

This application shows how to integrate the adtonik-mobile-sdk in a single window application. The application logic itself is just a placeholder and I simply took a screenshot of a weather application and set it as the background. The top of the view contains a UIWebView which renders an HTML banner ad when an audio ACR result is received from the API server.

**Setting up ADTAudioACR object**

Open the main view controller (ADTViewController) for the DemoApp. Note the property audioACR of the type ADTClient.

    __ADTViewController.h__

    @interface ADTViewController : UIViewController <ADTClientDelegate> {
      ADTClient *_audioACR;
    }

    @property (nonatomic, retain) ADTClient *audioACR;

Now open ADTViewController.m and see how audioACR is initialized in when the view is loaded.

__ADTViewController.m__

    - (void)viewDidLoad
    {
      ADTClient *newAudioACR = [[ADTClient alloc] initWithDelegate:self doRefresh:YES andAppID:APP_ID andAppSecret:APP_SECRET];

      self.audioACR = newAudioACR;
      [newAudioACR release];

      // start it up
      [self.audioACR start];
    }

Here we initialize a new ADTClient object and set the delegate to self. It is mandatory to pass in a ADTClientDelegate object. Pass the AdTonik assigned APP_ID and APP_SECRET to the ADTClient constructor.

There are two ways at the current time to run the ACR process. The first is to call initWithDelegate with the refresh flag set to YES. This means that after every cycle of turning on the microphone, taking an audio sample, processing the audio and querying the api server for results, it will be re-run. Even if an error is experienced and the error delegate methods are called, if it is possible to continue despite the error, it will continue to run. If you do choose to set refresh to YES, note that when you are truly finished running the ACR process, you can simply call [audioACR stop] at any time.

The second way is by setting the refresh flag to NO. When this is the case, the ACR process will happen once. After the delegate methods are called upon receiving results or experiencing an error, the ACR process will be stopped. If you would like to manually turn it back on, you can call [audioACR start] to fire it back up.

#### Delegate Methods

You must implement the delegate protocol in one of your classes in order to receive events from ADTClient.

Look at DemoApp's ADTViewController class which implements the ADTClientDelegate protocol.

    // Mandatory delegate methods
    - (void) ADTClientDidReceiveMatch:(NSDictionary *)results
    {
      NSLog(@"Received results %@", results);
    }

    - (void)ADTClientDidReceiveAd
    {
      NSLog(@"AdTonik has ad for device");
    }

    // Optional delegate methods
    - (void)ADTClientErrorDidOccur:(NSError *)error
    {
      NSLog(@"ADTClient error occurred: %@", error);
    }
    
    - (void)ADTClientDidFinishSuccessfully
    {
      NSLog(@"ADTClient Complete!");
    }

The method `ADTClientDidReceiveMatch` is called when ADTClient has recognized television content. The method `ADTClientDidReceiveAd` is called when an ad has been prepared for this device. This method is typically the one you would initiate an ad to be rendered in the view using the ad SDK your app uses.

The `ADTClientErrorDidOccur` method is called upon an API or audio processing error. Lastly, the `ADTClientDidFinishSuccessfully` method is called upon completion. 

##### Overriding the Device ID

AdTonik enables re-targeting television related advertisements to the mobile device by keeping track of what TV content this device has matched. To properly serve targeted advertisements, the device ID must be the same as the device ID used in the ad SDK. AdTonik uses a SHA1 hashed Identifier For Advertising (IFA) in iOS 6 and a SHA1 hashed deviceIdentifier for < iOS 6. These are industry standards, however if you do need to override the device ID generation, implement the `ADTClientUDID` method to return the same device ID as your ad SDK.

    - (NSString *)ADTClientUDID;

#### Questions

Feel free to contact me directly at marshall@adtonik.com.
