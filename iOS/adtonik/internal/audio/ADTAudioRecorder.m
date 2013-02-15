//
//  ADTAudioRecorder.m
//  ADTClient
//
//  Created by Marshall Beddoe on 4/9/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ADTAudioRecorder.h"
#import "ADTLogging.h"

@interface ADTAudioRecorder () <AVAudioRecorderDelegate>

@property (nonatomic, strong) NSURL *filename;
@property (nonatomic, strong) AVAudioRecorder  *audioRecorder;
@property (nonatomic, weak) id<ADTAudioRecorderDelegate> delegate;
@property (nonatomic, strong) NSDictionary* recordSettings;
@property (nonatomic, assign) NSTimeInterval duration;

@end

@implementation ADTAudioRecorder

#pragma mark -
#pragma mark Initializing an ADTAudioRecorder Object

- (id)initWithDelegate:(id<ADTAudioRecorderDelegate>)delegate
{
  self = [self init];

  if(self) {
    _delegate = delegate;
  }

  return self;
}

- (id)init
{
  if(self = [super init]) {

    _recordSettings = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
                       AVSampleRateKey: @8000.0f,
                       AVNumberOfChannelsKey: @1,
                       AVLinearPCMBitDepthKey: @16,
                       AVEncoderAudioQualityKey: @(AVAudioQualityMax),
                       AVSampleRateConverterAudioQualityKey: @(AVAudioQualityMax),
                       AVLinearPCMIsFloatKey: @YES};
  }

  return self;
}

#pragma mark -
#pragma mark Controlling Recording

- (BOOL)record:(NSTimeInterval)duration
{

  if(self.isRecording) {
    ADTLogWarn(@"Called record while ADTAudioRecorder is already recording..");
    return NO;
  }

  self.duration = duration;

  // Generate temporary filename for our recording session
  self.filename = [NSURL fileURLWithPath:[self generateUniqueFilename]];

  ADTLogInfo(@"Starting audio analysis");

  NSError *recordError = nil;
  
  AVAudioRecorder *newAudioRecorder = [[AVAudioRecorder alloc] initWithURL: self.filename
                                                                  settings: self.recordSettings
                                                                      error: &recordError];


  if(!newAudioRecorder) {
    ADTLogError(@"(ADTClient) Error setting up AVAudioRecorder: %@",
                [recordError localizedDescription]);
    return NO;
  }

  self.audioRecorder = newAudioRecorder;
  
  // Set as delegate to receive events upon recording error or completion..
  [self.audioRecorder setDelegate: self];

  // Kick off async record operation
  if([self.audioRecorder recordForDuration:duration] == NO) {
    ADTLogError(@"AudioRecorder returned FALSE");
  }

  self.recording = YES;

  return YES;
}

- (void)stop {
  if(self.isRecording) {
    ADTLogInfo(@"Stopping audio recorder..");
    [self.audioRecorder stop];
    self.recording = NO;
  }
}

#pragma mark -
#pragma mark Audio Recorder Delegate Methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
  if(self.recording == NO)
    return;
  
  self.recording = NO;

  if(flag == YES) {
    ADTLogInfo(@"Successfully recorded audio to %@", self.filename);
  } else {
    ADTLogInfo(@"Audio record did not complete successfully..");
  }

  if([self.delegate respondsToSelector:@selector(recorderFinished:successfully:)]) {
    [self.delegate recorderFinished:self.filename successfully:flag];
  }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
  if(self.recording == NO)
    return;

  self.recording = NO;

  ADTLogInfo(@"An encoder error occurred while recording audio %@", error);

  if([self.delegate respondsToSelector:@selector(recorderFailure:)]) {
    [self.delegate recorderFailure:error];
  }

  [recorder deleteRecording];
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder
{
  ADTLogInfo(@"Audio recorder began interruption..pausing recording");
  [self.audioRecorder pause];
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags
{
  if(flags == AVAudioSessionInterruptionFlags_ShouldResume) {
    ADTLogInfo(@"Audio recorder interruption ended.. resuming");
    // for some reason audioRecorder record doesn't resume with original duration..
    [self.audioRecorder recordForDuration:self.duration];
    self.recording = YES;
  } else {
    ADTLogInfo(@"Audio recorder cannot recover from interruption.. stopping it.");
    self.recording = NO;
    [recorder deleteRecording];
  }
}

#pragma mark -
#pragma mark Generate Temporary Filename

- (NSString *)generateUniqueFilename
{
  CFUUIDRef uuid = CFUUIDCreate(NULL);
  CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);

  NSString *uniqueFileName = [NSString stringWithFormat:@"%@%@.caf", @"adt-", (__bridge NSString *)uuidString];
  NSString *recordFile = [NSTemporaryDirectory() stringByAppendingPathComponent: uniqueFileName];

  CFRelease(uuid);
  CFRelease(uuidString);

  return recordFile;
}

@end
