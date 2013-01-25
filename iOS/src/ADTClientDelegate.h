//
//  ADTClientDelegate.h
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/11/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

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

 @param results NSDictionary containing meta-data of the content that was matched
 */

- (void)ADTClientDidReceiveMatch:(NSDictionary *)results;

/**
 Called by the system when an ad is available for this device.

 @param results NSDictionary containing meta-data of the content that was matched
 @param flag The flag indicating a sucessful match (YES), or failure (NO)
 */

- (void)ADTClientDidReceiveAd;

/**
 Optional method to override the UDID method. UDID must match the UDID the Ad SDK uses.
 If you do not specify this method, we use the IFA on iOS 6 and sha1 udid for iOS < 6.
 */
- (NSString *)ADTClientUDID;

/**
 Called by the system when ACR is completed.
 */
- (void)ADTClientDidFinishSuccessfully;

/**
 Called by the system when an error occurs.
 */
- (void)ADTClientErrorDidOccur:(NSError *)error;

@end
