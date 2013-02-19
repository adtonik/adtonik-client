//
//  ADTClientDelegate.h
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/11/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

@class ADTClient;

/**
 The delegate of an ADTClient object must adopt the ADTClientDelegate protocol.
 These methods allow the delegate to receive ACR results and be notified upon errors.

 When you register your application with AdTonik, you will be given an appID and an
 appSecret. Both of these must be specified in the delegate object.
 */
@protocol ADTClientDelegate <NSObject>

@optional

/**
 Called by the system when results have been received from the API server.

 The AdTonik API does not normally pass results back to the client. This method
 is only used for debugging and demo purposes.

 In the context of ad serving, implement ADTClientDidReceiveAd or
 ADTClientDidReceiveAdsWithDimensions:

 @param results NSDictionary containing meta-data of the content that was matched
 */

- (void)ADTClientDidReceiveMatch:(NSDictionary *)results;

/**
 Called by the system when an ad is available for this device.
 */

- (void)ADTClientDidReceiveAd:(ADTClient *)adtonik;

/**
 Optional method to override the AdvertiserIdentifier method. AdTonik uses the IFA to pair the
 ad call to the tv data, therefore this method must return the same IFA used by your chosen ad sdk.

 By default, we use the IdentifierForAdvertising on iOS 6.0+ and the SHA1 hashed deviceIdentifier
 for previous iOS versions.
 */
- (NSString *)ADTAdvertiserIdentifier;

/**
 Called by the system when the ACR process is complete. If doRefresh is set to YES, this method
 will only be executed when the caller calls the stop method.
 */
- (void)ADTClientDidFinishSuccessfully;

/**
 Called by the system when an error occurs.
 */
- (void)ADTClientErrorDidOccur:(NSError *)error;

/**
 These callbacks are executed when the info panel is about to be presented or dismissed as a modal
 view. Your application may need to perform an action when the modal is displayed (i.e.: pausing
 the game).
 */

// TODO: redundant, use the same ones as the AdView..

- (void)ADTWillPresentInfoPaneView:(ADTClient *) client;
- (void)ADTDidDismissInfoPaneView:(ADTClient *) client;

@end
