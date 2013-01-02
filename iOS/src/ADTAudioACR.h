//
//  ADTAudioACR.h
//  ADTAudioACR
//
//  Created by Marshall Beddoe on 3/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTAudioACRDelegate.h"

/**
 An instance of the ADTAudioACR class discovers what a user is watching on television using
 audio automated content recognition technology. This works by turning on the microphone and taking
 a sample, processing the raw audio to pull out fingerprints and then querying the ACR api server
 to receive the results.

 You can either run the ACR process once or have it automatically refresh by setting the refresh
 flag to YES in the initializer method.

 You must setup a class to be an ADTAudioACRDelegate to receive notifications when a result has
 been received or if an error occurred. If refresh was set to YES, it will continue to run in the
 background. To stop, call the stop method on the ACR object in the delegate callbacks.

 @note:
 Please expect in the very near future for the server to specify the refresh time amount dynamically,
 so it can be put to sleep if our algorithm believes the user is not in front of a TV.
 */

@interface ADTAudioACR : NSObject

// Returns true if the ACR process is running.
@property (getter=isRunning) BOOL running;

// Delegate object that receives notifications upon api errors,
// audio processing errors as well as when the server returns results..
@property (nonatomic, assign) id <ADTAudioACRDelegate> delegate;

#pragma mark -
#pragma mark Collecting SDK Version

// Returns the version of the SDK
+ (NSString *) sdkVersion;

#pragma mark -
#pragma mark Initializers

///---------------------------------------------------------------------------------------
/// @name Initializing an ADTAudioACR Object
///---------------------------------------------------------------------------------------

/**
 Initializes the audio ACR object

 By default, the refreshFlag is set to NO. This means after making the delegate callbacks, the acr
 process will be stopped. You may manually call start again if desired or instead initialize object
 with refreshFlag to YES.

 - [ADTAudioACRDelegate acrAPIReceivedResults:successfully:] is called upon receiving results from the api server
 - [ADTAudioACRDelegate acrAPIErrorDidOccur:] is called when there is an API server error
 - [ADTAudioACRDelegate acrAudioProcessingError:] is called when there is a recording error

 @param delegate The ADTAudioACRDelegate object
 @return Returns initialized instance or `nil` if initialization fails.
 */

- (id) initWithDelegate:(id<ADTAudioACRDelegate>) delegate;

/**
 Initializes the audio ACR object

 - [ADTAudioACRDelegate acrAPIReceivedResults:successfully:] is called upon receiving results from the api server
 - [ADTAudioACRDelegate acrAPIErrorDidOccur:] is called when there is an API server error
 - [ADTAudioACRDelegate acrAudioProcessingError:] is called when there is a recording error

 @param delegate The ADTAudioACRDelegate object
 @param refreshFlag Set to YES to continue to run in background
 @return Returns initialized instance or `nil` if initialization fails.
 */

- (id) initWithDelegate:(id<ADTAudioACRDelegate>) delegate refresh: (BOOL) refreshFlag;


#pragma mark -
#pragma mark ACR process control methods

/**
 Call start to begin ACR process.

 @return YES if start was successful
 */

- (BOOL) start;

/**
 Call stop to end ACR process.

 @return YES if stop was successful
 */

- (BOOL) stop;

#pragma mark -
#pragma mark Deallocate

/**
 Deallocate ACR object and cleanup.
 */

- (void) dealloc;
@end
