//
//  ADTAudioACRDelegate.h
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/11/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 The delegate of an ADTAudioACR object must adopt the ADTAudioACRDelegate protocol.
 These methods allow the delegate to receive ACR results and be notified upon errors.
 
 When you register your application with AdTonik, you will be given an appID and an
 appSecret. Both of these must be specified in the delegate object.
 */
@protocol ADTAudioACRDelegate <NSObject>

/** 
 Must return an NSString containing the application ID assigned to you from AdTonik.
 */
- (NSString *) acrAppId;

/** 
 Must return an NSString containing the application secret assigned to you from AdTonik.
 */
- (NSString *) acrAppSecret;

/** 
 Called by the system when results have been received from the API server.
 
 @param results NSDictionary containing meta-data of the content that was matched
 @param flag The flag indicating a sucessful match (YES), or failure (NO)
 */

- (void) acrAPIDidReceivedResults: (NSDictionary *) results matchedSuccessfully: (BOOL) flag;

@optional

/**
 Optional method to override the UDID method. UDID must match the UDID the Ad SDK uses.
 If you do not specify this method, we use the IFA on iOS 6 and sha1 udid for iOS < 6.
 */
- (NSString *) acrUDID;

/** 
 Called by the system when an API error occurs.
 
 @param error NSString containing the error message from the server
 */
- (void) acrAPIErrorDidOccur: (NSString *) error;

/** 
 Called by the system when a recording error occurs.
 
 @param error NSString containing the error message
 */
- (void) acrAudioProcessingErrorDidOccur: (NSString *) error;

/**
 Called by the system when ACR is completed. 
 */
- (void) acrDidFinishSuccessfully;

@end
