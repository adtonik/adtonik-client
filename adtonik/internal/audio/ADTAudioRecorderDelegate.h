//
//  ADTAudioRecorderDelegate.h
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/17/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 The delegate of an ADTAudioRecorder object must adopt the ADTAudioRecorderDelegate protocol.
 All of these methods are required. They allow the delegate to respond to audio recording errors and
 to the completion of recording.
*/

@protocol ADTAudioRecorderDelegate <NSObject>

/** 
 Called by the system when a recording has completed.
  
 @param filename The filename containing the audio data
 @param flag The flag indicating success (YES), or failure (NO)
*/

- (void)recorderFinished:(NSURL *)filename successfully:(BOOL)flag;

/** 
 Called by the system when a recording experiences an unrecoverable error.
 
 @param error The recording error
*/

- (void)recorderFailure:(NSError *)error;

@end
