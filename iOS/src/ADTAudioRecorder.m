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
@property (nonatomic, copy)   NSString *defaultCategory;
@property (nonatomic, copy)   NSString *defaultMode;
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

    _defaultCategory = [[AVAudioSession sharedInstance] category];
    _defaultMode     = [[AVAudioSession sharedInstance] mode];
  }

  return self;
}

#pragma mark -
#pragma mark Deallocate


#pragma mark -
#pragma mark Controlling Recording

- (BOOL)record:(NSTimeInterval)duration
{

  if(self.isRecording) {
    ADTLogWarn(@"Called record while ADTAudioRecorder is already recording..");
    return NO;
  }

  self.duration = duration;

  // Set the audio session category to play and record to enable the microphone..
  NSError *audioSessionError = nil;
  BOOL result = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                                  error: &audioSessionError];

  if(!result) {
    ADTLogError(@"Error setting AVAudioSession category to PlayAndRecord: %@", audioSessionError);
    return NO;
  }

  UInt32 allowMixing = true;
  
  AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers,  // 1
                           sizeof (allowMixing),                                 // 2
                           &allowMixing                                          // 3
                           );
    
  [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeMeasurement error:nil];

  // Generate temporary filename for our recording session
  self.filename = [NSURL fileURLWithPath:[self generateUniqueFilename]];

  ADTLogInfo(@"Recording audio to %@", self.filename);

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
  
  // After file is processed, delete from disk and reset the audio session category to default..
  // [recorder deleteRecording];
  
  [self resetAudioSessionCategory];
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

  // TODO: call observer when completed. observer's responsibility should be to reset
  // the audio session category to default. we should do this in one place so we do
  // not introduce a bug by forgetting to reset the audio session category when complete.
  [recorder deleteRecording];
  
  [self resetAudioSessionCategory];
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
    [self resetAudioSessionCategory];
  }
}

#pragma mark -
#pragma mark Reset Audio Session Category

- (void)resetAudioSessionCategory
{
  self.filename = nil;
  ADTLogInfo(@"Resetting Audio Session Category back to %@", self.defaultCategory);

  [[AVAudioSession sharedInstance] setCategory:self.defaultCategory error: nil];
  [[AVAudioSession sharedInstance] setMode:self.defaultMode error: nil];
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
