Integration Instructions
==========================

Step 1: Add the AdTonik source code to your app.
--
Add the contents of iOS/adtonik folder into your project. If you use MoPub include the integrations/mopub folder also.

Step 2 - Include required frameworks.
------

Add the following frameworks to your project if they do not already exist:
* UIKit.framework
* Foundation.framework
* AdSupport.framework
* Accelerate.framework
* AVFoundation.framework
* AudioToolbox.framework
* QuartzCore.framework

Verify the following resources were added to your project:
* ADTIcon.png & ADTIcon@2x.png
* ADTCloseButton.png & ADTCloseButton@2x.png
* ADTBrowserController.xib

Step 3 - Receive app id and app secret from AdTonik

Email support@adtonik.com with the following information to receive your appID and appSecret:

- Application Name
- Company Name
- Description
- Contact Email

Step 4 - Initialize and start ADTClient
---
Add an ADTClient object in your main view. Include the provided app id and app secret. As Apple requires a visual notification when the microphone is activated, we have provided an icon that pulses when the mic is active. When the spinner is tapped, it opens up a modal browser with options for the user. Activate the spinner by providing a coordinate where it should render and the view controller for handling the modal.

    ADTClient *adtonik = [[ADTClient alloc] initWithDelegate:self doRefresh:YES appID:YOUR_APP_ID appSecret:@YOUR_APP_SECRET];

    [adtonik showSpinner:CGPointMake(0,0) rootViewController:self];

    [adtonik start];


The most common place to instantiate ADTClient is the viewDidLoad method. Note that since ADTClient requires the AudioSession category to be equal to AVAudioSessionCategoryPlayAndRecord, you may need to create the ADTClient after your app has already initialized its audio session. This is most common in games and in this situation you would initialize and start the ADTClient after the game initialized the audio session. See the example game AdTonik integration at http://github.com/adtonik/climbers.

Step 5 - Setup Ad Serving
---

AdTonik supports multiple ways to serve TV related advertisements in your application.  At the current time, we recommend using a mediation SDK such as MoPub.  If you wish to integrate ad serving directly, please contact support.

To see an example mopub integration, see http://github.com/adtonik/example-mopub-integration

We have a MoPub custom event adapter that allows our ads to be served using MoPub for mediation. To use, include the integrations/mopub source code in your project and modify the ADTBannerEvent & ADTInterstitialEvent files to include your provided APP_ID. For more instructions on configuring MoPub to serve AdTonik ads, contact us.

### For any questions please email support@adtonik.com
