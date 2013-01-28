//
//  ADTClient.h
//  ADTClient
//
//  Created by Marshall Beddoe on 3/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTClientDelegate.h"

/**
 An instance of the ADTClient class discovers what a user is watching on television using
 audio automated content recognition technology. This works by turning on the microphone and taking
 a sample, processing the raw audio to pull out fingerprints and then querying the ACR api server
 to receive the results.

 You can either run the ACR process once or have it automatically refresh by setting the refresh
 flag to YES in the initializer method.

 You must setup a class to be an ADTClientDelegate to receive notifications when a result has
 been received or if an error occurred. If refresh was set to YES, it will continue to run in the
 background. To stop, call the stop method on the ACR object in the delegate callbacks.

 @note:
 Please expect in the very near future for the server to specify the refresh time amount dynamically,
 so it can be put to sleep if our algorithm believes the user is not in front of a TV.
 */

@interface ADTClient : NSObject

// Returns true if the ACR process is running.
@property (getter=isRunning) BOOL running;

// Returns the Identifier for Advertising
@property (nonatomic, copy) NSString* ifa;

// Returns the last error that occurred
@property (nonatomic, copy, getter=lastError) NSError* error;

// Delegate object that receives notifications upon api errors,
// audio processing errors as well as when the server returns results..
@property (nonatomic, weak) id <ADTClientDelegate> delegate;

#pragma mark -
#pragma mark Collecting SDK Version

// Returns the version of the SDK
+ (NSString *)sdkVersion;

#pragma mark -
#pragma mark Initializers

///---------------------------------------------------------------------------------------
/// @name Initializing an ADTClient Object
///---------------------------------------------------------------------------------------

/**
 Initializes the audio ACR object

 @param delegate The ADTClientDelegate object
 @param refreshFlag Set to YES to continue to run in background
 @param appID The AdTonik assigned appID
 @param appSecret The AdTonik assigned appSecret

 @return Returns initialized instance or `nil` if initialization fails.
 */

- (id)initWithDelegate:(id<ADTClientDelegate>)delegate
             doRefresh:(BOOL)refreshFlag
              andAppID:(NSString *)appID
          andAppSecret:(NSString *)appSecret;


#pragma mark -
#pragma mark ACR process control methods

/**
 Call start to begin ACR process.

 @return YES if start was successful
 */

- (BOOL)start;

/**
 Call stop to end ACR process.

 @return YES if stop was successful
 */

- (BOOL)stop;

@end
