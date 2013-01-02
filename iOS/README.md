# AdTonik Mobile SDK

The AdTonik Mobile SDK currently implements our audio automated content recognition technology. Future functionality
will include a mobile ad sdk client which can act as a mediation layer as well as directly pull ads from the AdTonik ad
server.

## API Documentation

You can view the API documents at [http://adtonik.net/docs](http://adtonik.net/docs)

## Integration

Go to [http://control.adtonik.net](http://control.adtonik.net) to register your application and generate an App ID
and App Secret which will be used in your ADTAudioACRDelegate.

See the examples/ directory to get an idea of how simple it is to integrate our SDK in an existing application.

### DemoApp

This application shows how to integrate the adtonik-mobile-sdk in a single window application. The application logic itself is just a placeholder and I simply took a screenshot of a weather application and set it as the background. The top of the view contains a UIWebView which renders an HTML banner ad when an audio ACR result is received from the API server.

**Setting up ADTAudioACR object**

Open the main view controller (ADTViewController) for the DemoApp. Note the property audioACR of the type ADTAudioACR.

__ADTViewController.h__

@interface ADTViewController : UIViewController <ADTAudioACRDelegate> {
  ADTAudioACR *audioACR_;
}

@property (nonatomic, retain) ADTAudioACR *audioACR;

Now open ADTViewController.m and see how audioACR is initialized in when the view is loaded.

__ADTViewController.m__

- (void)viewDidLoad
{
  …

    ADTAudioACR *newAudioACR = [[ADTAudioACR alloc] initWithDelegate:self refresh:YES];

  self.audioACR = newAudioACR;
  [newAudioACR release];

  // start it up
  [self.audioACR start];

  ...
}

All we are doing here is initializing a new ADTAudioACR object and setting the delegate to the ADTViewController object. It is mandatory to pass in a ADTAudioACRDelegate object. This delegate has methods that specify the appID and appSecret that is assigned to you when you register your application on the AdTonik site.

There are two ways at the current time to run the ACR process. The first is to call initWithDelegate with the refresh flag set to YES. This means that after every cycle of turning on the microphone, taking an audio sample, processing the audio and querying the api server for results, it will be re-run. Even if an error is experienced and the error delegate methods are called, if it is possible to continue despite the error, it will continue to run. If you do choose to set refresh to YES, note that when you are truly finished running the ACR process, you can simply call [audioACR stop] at any time.

The second way is by setting the refresh flag to NO. When this is the case, the ACR process will happen once. After the delegate methods are called upon receiving results or experiencing an error, the ACR process will be stopped. If you would like to manually turn it back on, you can call [audioACR start] to fire it back up.

#### Delegate Methods

The ADTAudioACRDelegate object is very important. You must implement the delegate protocol in one of your classes in order to receive events whenever an error occurs or when results are received. The protocol also implements two important methods acrAppID and acrAppSecret which return an NSString containing the application ID and application secret that is assigned to you when your application was registered at adtonik.com.

Look at DemoApp's ADTViewController class which implements the ADTAudioACRDelegate protocol.

- (NSString *) acrAppId {
  return @"appID"; // replace with the appID value assigned to you by adtonik
}

- (NSString *) acrAppSecret {
  return @"appSecret"; // replace with the appSecret value assigned to you by adtonik
}

- (void) acrAPIReceivedResults: (NSDictionary *) results successfully:(BOOL) flag {
  if(flag == YES) {
    NSString *url  = [results objectForKey:@"url"];

    if(url != NULL) {
      [webView_  loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
  }
}

- (void) acrAPIErrorDidOccur: (NSString *) error {
  NSLog(@"Encountered API ERROR %@", error);
}

- (void) acrAudioProcessingError: (NSString *) error {
  NSLog(@"Encountered audio processing error %@", error);
}

There are three methods that are required to be implemented: acrAppID, acrAppSecret and acrAPIReceivedResults:successfully:. The first two methods simply return an NSString object containing the credentials assigned to you when your application was registered at adtonik.com.

The method acrAPIReceivedResults:successfully: is called when the API server responds to your request. The API server returns a JSON hash of metadata related to the content. Depending on whether the content is a commercial, television show, movie or song, the metadata can be different. We are standardizing on the required values that will be contained in the NSDictionary, but a few things can be expected: name, url, description. In this demo application, I am only interested in pulling out the URL containing a banner image which can be rendered in the UIWebView. As shown above, if the server was able to find a match, it calls the delegate method with the success flag set to YES. If the server responds with a match, I pull out the URL field from the dictionary and render it in the webview.

This concludes the description of how the DemoApp is designed. If you have any other questions, feel free to contact me directly.

**Marshall Beddoe**

**marshall@adtonik.com**

**(415) 505-4203**
