//
//  ADTClient.m
//  ADTClient
//
//  Created by Marshall Beddoe on 3/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTClient.h"
#import "ADTAudioRecorder.h"
#import "ADTAudioRecorderDelegate.h"
#import "ADTRestAPI.h"

#import "ADTConstants.h"
#import "ADTLogging.h"
#import "ADTlibacrWrapper.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
#import <AdSupport/AdSupport.h>
#endif

#import <CommonCrypto/CommonDigest.h>

@interface ADTClient () <ADTAudioRecorderDelegate, ADTRestAPIDelegate>

@property (getter=doRefresh)    BOOL              refresh;
@property (nonatomic, retain)   ADTAudioRecorder* audioRecorder;
@property (nonatomic, retain)   NSOperationQueue* acrQueue;
@property (nonatomic, retain)   ADTRestAPI*       restAPI;
@property (nonatomic, assign)   NSUInteger        sampleDuration;

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
  self = [self initWithDelegate:delegate andAppID:appID andAppSecret:appSecret];

  if(self) {
    _refresh = refreshFlag;
  }

  return self;
}

- (id)initWithDelegate:(id<ADTClientDelegate>)delegate
              andAppID:(NSString *)appID
          andAppSecret:(NSString *)appSecret
{
  self = [super init];

  if(self) {
    _delegate  = delegate;
    _acrQueue  = [[NSOperationQueue alloc] init];
    _sampleDuration = ADT_SAMPLE_SECONDS;
    _udid      = [[self getUDID] retain];
    
    _restAPI   = [[ADTRestAPI alloc] initWithDelegate:self andAppId:appID andAppSecret:appSecret andUDID:_udid];

    // make sure allocations successful, bail otherwise.
    if(!_acrQueue || !_restAPI) {
      ADTLogError(@"ADTClient initWithDelegate failed..");
      [self release];
      return nil;
    }
  }

  return self;
}

#pragma mark -
#pragma mark Deallocate

- (void)dealloc
{
  [_audioRecorder release];
  [_acrQueue release];
  [_restAPI release];
  [_udid release];

  [super dealloc];
}

#pragma mark -
#pragma mark ACR process control methods

- (BOOL)start
{
  // Need to decide what we want to return here..
#if TARGET_IPHONE_SIMULATOR
  NSLog(@"ADTClient cannot run in the simulator, returning..");
  return NO;
#endif

  if(self.isRunning) {
    ADTLogError(@"acr is already running..");
    return NO;
  }

  self.running = YES;

  [self.acrQueue setMaxConcurrentOperationCount:1];

  return [self queueOperation];
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
  [acrOperation release];

  return YES;
}

#pragma mark -
#pragma mark Starts Asynchronous Operations

- (void)startAsyncOperations
{
  self.audioRecorder = [[[ADTAudioRecorder alloc] initWithDelegate:self] autorelease];
  [self.audioRecorder record:self.sampleDuration];
}

- (BOOL) stop
{
  if(self.isRunning) {
    if(self.audioRecorder.isRecording)
      [self.audioRecorder stop];

    if(self.restAPI.isLoading)
      [self.restAPI cancel];

    self.running = NO;

    if([self.delegate respondsToSelector:@selector(ADTClientDidFinishSuccessfully)])
      [self.delegate ADTClientDidFinishSuccessfully];

    return YES;
  }

  return NO;
}

#pragma mark -
#pragma mark Called when ACR process completes

- (void) finishedRun
{
  self.audioRecorder = nil;

  // Refresh process if necessary
  if([self doRefresh] && self.isRunning == YES) {
    [self performSelectorInBackground:@selector(startTimer) withObject:nil];
  } else {
    self.running = NO;

    if([self.delegate respondsToSelector:@selector(ADTClientDidFinishSuccessfully)])
      [self.delegate ADTClientDidFinishSuccessfully];
  }
}

#pragma mark -
#pragma mark Schedules ACR process to run

// This must be started in a background thread or call stack will grow recursively
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
#pragma mark Run ACR algorithm on fingerprint file

- (void) runAlgorithm:(NSString *) filename
{
  NSSet *fingerprints = [ADTlibacrWrapper getFingerprintsForFile:filename];

  // It is now our responsibility to delete the file
  NSError *error = nil;
  [[NSFileManager defaultManager] removeItemAtPath:filename error:&error];

  if(error)
    ADTLogError(@"Unable to delete file %@", filename);

  // Query the api server in the main thread
  [self performSelectorOnMainThread:@selector(queryAPIServer:) withObject:fingerprints waitUntilDone:NO];
}

#pragma mark -
#pragma mark Query API server with fingerprint set

- (void) queryAPIServer:(NSSet *) fingerprints
{
  NSString *acrVersion = [ADTlibacrWrapper getACRVersion];

  if(!fingerprints || [fingerprints count] == 0) {
    ADTLogError(@"ACR process ending: no fingerprints found in set");

    if([self.delegate respondsToSelector:@selector(ADTClientErrorDidOccur:)]) {
      NSError *error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAudioNoFingerprints userInfo:nil];
      [self.delegate ADTClientErrorDidOccur:error];
    }
  }

  ADTLogInfo(@"Received %d total fingerprints", [fingerprints count]);

  if([self.restAPI queryWithFingerprints:fingerprints andVersion:acrVersion] == NO) {
    ADTLogError(@"ACR process ending: queryWithFingerprints failed");

    if([self.delegate respondsToSelector:@selector(ADTClientErrorDidOccur:)]) {
      NSError *error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTError userInfo:nil];
      [self.delegate ADTClientErrorDidOccur:error];
    }
  }
}

#pragma mark -
#pragma mark Lookup UDID for device

NSString *ADTSHA1Digest(NSString *string)
{
  unsigned char digest[CC_SHA1_DIGEST_LENGTH];
  NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
  CC_SHA1([data bytes], [data length], digest);
  
  NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
    [output appendFormat:@"%02x", digest[i]];
  }
  
  return output;
}

- (NSString *) getUDID
{
  NSString *identifier = nil;
  
  if([self.delegate respondsToSelector:@selector(ADTClientUDID)]) {
    return [self.delegate ADTClientUDID];
  }
  
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
  identifier = ADTSHA1Digest([[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString]);
#else
  identifier = ADTSHA1Digest([[UIDevice currentDevice] uniqueIdentifier]);
#endif
  
  return identifier;
}

#pragma mark -
#pragma mark ACRAudioRecorder Delegate Methods

- (void)recorderFinished:(NSURL *)filename successfully:(BOOL)flag
{
  if(flag == YES) {
    ADTLogInfo(@"successfully recorded audio.. generating fingerprints");

    // Process fingerprints in background thread
    [self performSelectorInBackground:@selector(runAlgorithm:) withObject:[filename path]];
  } else {
    ADTLogInfo(@"ACR process ending: recorderFinished experienced and error..");

    if([self.delegate respondsToSelector:@selector(ADTClientErrorDidOccur:)]) {
      NSError *error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAudioError userInfo:nil];
      [self.delegate ADTClientErrorDidOccur:error];
    }

    self.audioRecorder = nil;
  }
}

- (void)recorderFailure:(NSError *)error
{
  ADTLogInfo(@"ACR process ending: recorderFinished experienced and error..");

  if([self.delegate respondsToSelector:@selector(ADTClientErrorDidOccur:)]) {
    NSError *error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAudioError userInfo:nil];
    [self.delegate ADTClientErrorDidOccur:error];
  }

  self.audioRecorder = nil;
}

#pragma mark -
#pragma mark ADTRestAPI Delegate Methods

- (void)restAPIDidReceiveResponse:(NSDictionary *)results successfully:(BOOL)flag
{
  if(flag) {
    if([results[@"hasAd"] boolValue] == YES) {
      if([self.delegate respondsToSelector:@selector(ADTClientDidReceiveAd)]) {
        [self.delegate ADTClientDidReceiveAd];
      }
    }
  
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
  if([self.delegate respondsToSelector:@selector(ADTClientErrorDidOccur:)]) {
    NSError *error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAPIError userInfo:nil];
    [self.delegate ADTClientErrorDidOccur:error];
  }

  [self finishedRun];
}

- (void)restAPIDidReceiveOptOut
{
  ADTLogInfo(@"Device is opted out.. stopping");

  self.running = NO;

  if([self.delegate respondsToSelector:@selector(ADTClientDidFinishSuccessfully)])
    [self.delegate ADTClientDidFinishSuccessfully];
}

@end
