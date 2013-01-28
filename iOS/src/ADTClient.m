//
//  ADTClient.m
//  ADTClient
//
//  Created by Marshall Beddoe on 3/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/NSKeyValueObserving.h>

#import "ADTAudioRecorder.h"
#import "ADTAudioRecorderDelegate.h"
#import "ADTClient.h"
#import "ADTConstants.h"
#import "ADTLogging.h"
#import "ADTAudioACR.h"
#import "ADTRestAPI.h"
#import "ADTUtils.h"

@interface ADTClient () <ADTAudioRecorderDelegate, ADTRestAPIDelegate>

@property (getter=doRefresh)  BOOL              refresh;
@property (nonatomic, strong) ADTAudioRecorder* audioRecorder;
@property (nonatomic, strong) NSOperationQueue* acrQueue;
@property (nonatomic, strong) ADTRestAPI*       restAPI;
@property (nonatomic, assign) NSUInteger        sampleDuration;

@end

@implementation ADTClient

#pragma mark -
#pragma mark Collecting SDK Information

+ (NSString *)sdkVersion {
  return kADTSDKVersion;
}

#pragma mark -
#pragma mark Initializers

- (id)initWithDelegate:(id<ADTClientDelegate>)delegate
             doRefresh:(BOOL)refreshFlag
              andAppID:(NSString *)appID
          andAppSecret:(NSString *)appSecret
{
  if(self = [super init]) {
    _refresh        = refreshFlag;
    _delegate       = delegate;
    _acrQueue       = [[NSOperationQueue alloc] init];
    _ifa            = [self getAdvertiserIdentifier];
    _sampleDuration = ADT_SAMPLE_SECONDS;
    _restAPI        = [[ADTRestAPI alloc] initWithDelegate:self
                                                  andAppId:appID
                                              andAppSecret:appSecret
                                                   andUDID:_ifa];
    
    // make sure allocations successful, bail otherwise.
    if(!_acrQueue || !_restAPI) {
      ADTLogError(@"ADTClient initWithDelegate failed..");
      return nil;
    }
  }

  return self;
}

#pragma mark -
#pragma mark ACR process control methods

- (BOOL)start
{
  // Need to decide what we want to return here..
#if TARGET_IPHONE_SIMULATOR
  NSLog(@"ADTClient cannot run in the simulator.. start failed.");
  return NO;
#endif

  if(self.isRunning) {
    ADTLogError(@"acr is already running..");
    return NO;
  }

  self.running = YES;

  [self.acrQueue setMaxConcurrentOperationCount:1];

  //
  //setup KVO observers
  //
  
  // when isRunning is set to NO
  [self addObserver:self forKeyPath:@"running" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];

  // when error is set
  [self addObserver:self forKeyPath:@"error" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
  
  return [self queueOperation];
}

- (BOOL) stop
{
  if(self.isRunning) {
    if(self.audioRecorder.isRecording)
      [self.audioRecorder stop];
    
    if(self.restAPI.isLoading)
      [self.restAPI cancel];
    
    self.running = NO;
        
    return YES;
  }
  
  return NO;
}

#pragma mark -
#pragma mark Handle KVO Events

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if([keyPath isEqual:@"running"]) {
    
    // is isRunning set to NO, call delegate finished method
    if(self.isRunning == NO && change[@"new"] != change[@"old"]) {      
      if(self.isRunning == NO && [self.delegate respondsToSelector:@selector(ADTClientDidFinishSuccessfully)])
        [self.delegate ADTClientDidFinishSuccessfully];
    }
    
  } else if([keyPath isEqual:@"error"]) {
    
    // if error is set, call delegate error method
    if(self.error && [self.delegate respondsToSelector:@selector(ADTClientErrorDidOccur:)]) {
      [self.delegate ADTClientErrorDidOccur:self.error];
    }
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}


#pragma mark -
#pragma mark Add Operation to Queue

- (BOOL)queueOperation
{
  NSInvocationOperation *acrOperation;

  acrOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                      selector:@selector(startAsyncOperations)
                                                        object:nil];

  [self.acrQueue addOperation:acrOperation];

  return YES;
}

#pragma mark -
#pragma mark Starts Asynchronous ACR Process

- (void)startAsyncOperations
{
  self.audioRecorder = [[ADTAudioRecorder alloc] initWithDelegate:self];
  [self.audioRecorder record:self.sampleDuration];
}

#pragma mark -
#pragma mark Finish ACR Process

- (void) finishedRun
{
  // If user specified refresh=YES and ADTClient is running, requeue ACR
  if([self doRefresh] && self.isRunning == YES) {
    [self performSelectorInBackground:@selector(startTimer) withObject:nil];
  } else {
    self.running = NO;
  }
}

#pragma mark -
#pragma mark Setup Timer to Schedule ACR process

// NOTE: This must be started in a background thread to avoid recursive execution
- (void) startTimer
{
  NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
  NSTimer *refreshTimer;

  ADTLogInfo(@"Scheduling ACR to run in %d seconds", self.restAPI.refreshTimer);

  refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.restAPI.refreshTimer
                                                  target:self
                                                selector:@selector(queueOperation)
                                                userInfo:nil
                                                 repeats:NO];

  [runLoop addTimer:refreshTimer forMode:NSRunLoopCommonModes];
  [runLoop run];
}


#pragma mark -
#pragma mark Run ACR Algorithm on Audio File

- (void) runAlgorithm:(NSString *) filename
{  
  // Asynchronously compute the audio signatures
  [ADTAudioACR computeSignatures:filename callback:^(NSSet *fingerprints, NSString *errorMessage) {
    
    // It is now our responsibility to delete the file
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filename error:&error];
    
    if(error) {
      ADTLogError(@"Error deleting file");
    }
    
    if(errorMessage || !fingerprints) {
      ADTLogError(@"Error computing fingerprints");
      self.error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTError userInfo:nil];
      return;
    }

    [self queryAPIServer:fingerprints];
  }];
}

#pragma mark -
#pragma mark Query API with Fingerprints

- (void) queryAPIServer:(NSSet *)fingerprints
{
  NSString *acrVersion = [ADTAudioACR getACRVersion];
  
  if(!fingerprints || [fingerprints count] == 0) {
    ADTLogError(@"Error during ACR: No fingerprints computed");
    self.error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAudioNoFingerprints userInfo:nil];
  }

  ADTLogInfo(@"Received %d total fingerprints", [fingerprints count]);

  // Async call to API server
  if([self.restAPI queryWithFingerprints:fingerprints andVersion:acrVersion] == NO) {
    ADTLogError(@"ACR process ending: queryWithFingerprints failed");
    self.error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTError userInfo:nil];
  }
}

#pragma mark -
#pragma mark Lookup Advertising Identifier

- (NSString *)getAdvertiserIdentifier
{
  // check method override in delegate
  if([self.delegate respondsToSelector:@selector(ADTAdvertiserIdentifier)]) {
    return [self.delegate ADTAdvertiserIdentifier];
  }

  NSString *identifier = ADTAdvertisingIdentifier();
  
  if(!identifier) {
    [NSException raise:@"Unable to get AdvertiserIdentifier"
                format:@"AdvertiserIdentifier required to use ADTClient, " \
                        "implement ADTAdvertiserIdentifier in the delegate"];
  }
  
  return identifier;
}

#pragma mark -
#pragma mark ACRAudioRecorder Delegate Methods

- (void)recorderFinished:(NSURL *)filename successfully:(BOOL)flag
{
  if(flag == YES) {
    ADTLogInfo(@"successfully captured audio. starting fingerprint generation.");
    [self runAlgorithm:[filename path]];
  } else {
    ADTLogInfo(@"ACR process ending: recorderFinished experienced and error..");

    self.running = NO;
    self.error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAudioError userInfo:nil];
  }
}

- (void)recorderFailure:(NSError *)error
{
  ADTLogInfo(@"ACR process ending: recorderFinished experienced and error..");

  self.running = NO;
  self.error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAudioError userInfo:nil];
}

#pragma mark -
#pragma mark ADTRestAPI Delegate Methods

- (void)restAPIDidReceiveResponse:(NSDictionary *)results successfully:(BOOL)flag
{
  if(flag) {
    // Notify delegate that an ad is now available for this device
    if([results[@"hasAd"] boolValue] == YES) {
      if([self.delegate respondsToSelector:@selector(ADTClientDidReceiveAd)]) {
        [self.delegate ADTClientDidReceiveAd];
      }
    }
  
    // Notify the delegate that a successful match occurred
    if([results[@"match"] boolValue] == YES) {
      if([self.delegate respondsToSelector:@selector(ADTClientDidReceiveMatch:)]) {
        [self.delegate ADTClientDidReceiveMatch:results[@"data"]];
      }
    }
  }
  
  [self finishedRun];
}

- (void)restAPIDidErrorOccur:(id)error
{
  ADTLogError(@"Experienced error from API server. Requeueing process");
  
  self.error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAPIError userInfo:nil];

  [self finishedRun];
}

- (void)restAPIDidReceiveOptOut
{
  ADTLogInfo(@"Received OPT-OUT message from API for Device.. stopping process");
  
  self.running = NO;
}

@end
