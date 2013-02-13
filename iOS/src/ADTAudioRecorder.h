//
//  ADTAudioRecorder.h
//  ADTClient
//
//  Created by Marshall Beddoe on 4/9/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTAudioRecorderDelegate.h"

/**
 An instance of the ADTAudioRecorder class turns on the microphone and records audio for a specified duration.

 This class handles interruptions and when possible pauses and resumes recording when continued.

 You must implement a delegate for an ADTAudioRecorder object to be notified of errors and the completion of a recording.

 @warning This class saves the current value of the AVAudioSession category and switches the session category to
 PlayAndRecord. Upon completion, it switches the AVAudioSession category back to the value it detected during instantiation.
 If you use a custom AVAudioSession category, make sure it is set before instantiating this object.

*/

@interface ADTAudioRecorder : NSObject

///---------------------------------------------------------------------------------------
/// @name Initializing an ADTAudioRecorder Object
///---------------------------------------------------------------------------------------

/**
 Initializes the audio recorder
 This is the designated initializer.

 - [ADTAudioRecorderDelegate recorderFinished:successfully:] is called when recording complete
 - [ADTAudioRecorderDelegate recorderFailure:] is called when recording experiences an error

 @param delegate The ADTAudioRecorderDelegate object
 @return Returns initialized instance or `nil` if initialization fails.
*/

- (id)initWithDelegate:(id<ADTAudioRecorderDelegate>)delegate;

///---------------------------------------------------------------------------------------
/// @name Controlling Recording
///---------------------------------------------------------------------------------------

/**
 Start recording audio

 @param duration The number of seconds of audio to record
 @return YES if record starts successfully, NO if record start fails.
*/

- (BOOL)record:(NSTimeInterval) duration;

/** Stops recording and closes the audio file */

- (void)stop;

///---------------------------------------------------------------------------------------
/// @name Get Information About Recording
///---------------------------------------------------------------------------------------

/** A Boolean value that indicates if the audio recorder is recording (YES), or not (NO) */

@property (getter=isRecording) BOOL recording;

@end
