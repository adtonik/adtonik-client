//
//  ADTAudioACR.m
//  ADTAudioACR
//
//  Created by Marshall Beddoe on 3/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTAudioACR.h"
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

@interface ADTAudioACR () <ADTAudioRecorderDelegate, ADTRestAPIDelegate>
{
@private
  BOOL running_;
  BOOL authorized_;
  BOOL refresh_;
  
  NSString *udid_;
  NSUInteger sampleDuration_;
  NSOperationQueue *acrQueue_;
  ADTRestAPI *restAPI_;
  ADTAudioRecorder *audioRecorder_;

  id<ADTAudioACRDelegate> delegate_;
}

@property (getter=doRefresh)    BOOL              refresh;
@property (nonatomic, retain)   ADTAudioRecorder* audioRecorder;
@property (nonatomic, retain)   NSOperationQueue* acrQueue;
@property (nonatomic, retain)   ADTRestAPI*       restAPI;
@property (nonatomic, copy)     NSString*         udid;
@property (nonatomic, assign)   NSUInteger        sampleDuration;

@end

@implementation ADTAudioACR

@synthesize running        = running_;
@synthesize delegate       = delegate_;
@synthesize audioRecorder  = audioRecorder_;
@synthesize acrQueue       = acrQueue_;
@synthesize restAPI        = restAPI_;
@synthesize sampleDuration = sampleDuration_;
@synthesize refresh        = refresh_;
@synthesize udid           = udid_;

#pragma mark -
#pragma mark Collecting SDK Information

+ (NSString *)sdkVersion {
  return ADT_SDK_VERSION;
}

// TODO: need delegate method to call when completely finished

#pragma mark -
#pragma mark Initializers

- (id) initWithDelegate:(id<ADTAudioACRDelegate>) delegate refresh:(BOOL)refreshFlag {
  self = [self initWithDelegate:delegate];

  if(self) {
    refresh_ = refreshFlag;
  }

  return self;
}

- (id) initWithDelegate:(id<ADTAudioACRDelegate>) delegate {
  self = [super init];

  if(self) {
    delegate_  = delegate;
    acrQueue_  = [[NSOperationQueue alloc] init];
    sampleDuration_ = ADT_SAMPLE_SECONDS;
    udid_      = [[self getUDID] retain];
    
    restAPI_   = [[ADTRestAPI alloc] initWithDelegate:self andAppId:[delegate acrAppId] andAppSecret:[delegate acrAppSecret] andUDID: udid_];

    // make sure allocations successful, bail otherwise.
    if(!acrQueue_ || !restAPI_) {
      ADTLogError(@"ADTAudioACR initWithDelegate failed..");
      [self release];
      return nil;
    }
  }

  return self;
}

#pragma mark -
#pragma mark Deallocate

- (void) dealloc {

  [audioRecorder_ release];
  [acrQueue_ release];
  [restAPI_ release];
  [udid_ release];

  [super dealloc];
}

#pragma mark -
#pragma mark ACR process control methods

- (BOOL) start {

  // Need to decide what we want to return here..
#if TARGET_IPHONE_SIMULATOR
  NSLog(@"ADTAudioACR cannot run in the simulator, returning..");
  return NO;
#endif

  if(self.isRunning) {
    return NO;
  }

  self.running = YES;

  [self.acrQueue setMaxConcurrentOperationCount:1];

  return [self queueOperation];
}

#pragma mark -
#pragma mark Add Operation to Queue
- (BOOL) queueOperation {

  NSInvocationOperation *acrOperation;

  acrOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                      selector:@selector(startAsyncOperations)
                                                        object:nil];

  [acrQueue_ addOperation:acrOperation];
  [acrOperation release];

  return YES;
}

#pragma mark -
#pragma mark Starts Asynchronous Operations

- (void) startAsyncOperations {
  self.audioRecorder = [[[ADTAudioRecorder alloc] initWithDelegate: self] autorelease];

  // TODO: update audioRecorder to use blocks instead of delegates..
  [self.audioRecorder record:self.sampleDuration];
}

- (BOOL) stop {
  if(self.isRunning) {
    if(audioRecorder_.isRecording)
      [self.audioRecorder stop];

    if(restAPI_.isLoading)
      [restAPI_ cancel];

    self.running = NO;

    // dereference audio recorder for autorelease
    self.audioRecorder = nil;

    return YES;
  }

  return NO;
}

#pragma mark -
#pragma mark Called when ACR process completes

- (void) finishedRun {
  // dereference audio recorder for autorelease
  self.audioRecorder = nil;

  // Refresh process if necessary
  if([self doRefresh])
    [self performSelectorInBackground:@selector(startTimer) withObject:nil];
}

#pragma mark -
#pragma mark Schedules ACR process to run

// This must be started in a background thread or call stack will grow recursively
- (void) startTimer {
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

- (void) runAlgorithm: (NSString *) filename {
  NSSet *fingerprints = [ADTlibacrWrapper getFingerprintsForFile:filename];

  // it is now our responsibility to delete the file..
  NSError *e = nil;
  [[NSFileManager defaultManager] removeItemAtPath:filename error:&e];

  if(e) {
    ADTLogError(@"Unable to delete file %@", filename);
  }

  // query the api server in the main thread..
  [self performSelectorOnMainThread:@selector(queryAPIServer:) withObject:fingerprints waitUntilDone:NO];
}

#pragma mark -
#pragma mark Query API server with fingerprint set

- (void) queryAPIServer:(NSSet *) fingerprints {
  NSString *acrVersion = [ADTlibacrWrapper getACRVersion];

  if(!fingerprints || [fingerprints count] == 0) {
    ADTLogError(@"ACR process ending: no fingerprints found in set");

    if([delegate_ respondsToSelector:@selector(acrAudioProcessingError:)]) {
      [delegate_ acrAudioProcessingError: @"Error recording audio"];
    }
  }

  ADTLogInfo(@"Received %d total fingerprints", [fingerprints count]);

  if([self.restAPI queryWithFingerprints:fingerprints andVersion:acrVersion] == NO) {
    ADTLogError(@"ACR process ending: queryWithFingerprints failed");

    if([delegate_ respondsToSelector:@selector(acrAudioProcessingError:)]) {
      [delegate_ acrAudioProcessingError: @"Error processing fingerprints"];
    }
  }
}

#pragma mark -
#pragma mark Lookup UDID for device

NSString *ADTSHA1Digest(NSString *string) {
  unsigned char digest[CC_SHA1_DIGEST_LENGTH];
  NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
  CC_SHA1([data bytes], [data length], digest);
  
  NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
  {
    [output appendFormat:@"%02x", digest[i]];
  }
  
  return output;
}

- (NSString *) getUDID {
  NSString *identifier = nil;
  
  if([delegate_ respondsToSelector:@selector(acrUDID)]) {
    return [delegate_ acrUDID];
  }
  
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
  identifier = [[[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString] uppercaseString];
#else
  identifier = [ADTSHA1Digest([[UIDevice currentDevice] uniqueIdentifier]) uppercaseString];
#endif
  
  return identifier;
}

#pragma mark -
#pragma mark ACRAudioRecorder Delegate Methods

- (void) recorderFinished:(NSURL *)filename successfully:(BOOL)flag {
  if(flag == YES) {
    ADTLogInfo(@"successfully recorded audio.. generating fingerprints");

    // Process fingerprints in background thread
    [self performSelectorInBackground:@selector(runAlgorithm:) withObject:[filename path]];
  } else {
    ADTLogInfo(@"ACR process ending: recorderFinished experienced and error..");

    if([delegate_ respondsToSelector:@selector(acrAudioProcessingError:)]) {
      [delegate_ acrAudioProcessingError: @"Error recording audio"];
    }

    self.audioRecorder = nil;
  }
}

- (void) recorderFailure: (NSError *) error {
  ADTLogInfo(@"ACR process ending: recorderFinished experienced and error..");

  if([delegate_ respondsToSelector:@selector(acrAudioProcessingError:)]) {
    [delegate_ acrAudioProcessingError: @"Error recording audio"];
  }

  self.audioRecorder = nil;
}

#pragma mark -
#pragma mark ADTRestAPI Delegate Methods

- (void) restAPIResponse:(NSDictionary *) results successfully:(BOOL) flag {
  
  if([delegate_ respondsToSelector:@selector(acrAPIReceivedResults:successfully:)])
    [delegate_ acrAPIReceivedResults: results successfully:flag];

  [self finishedRun];
}

- (void) restAPIError:(id) error {

  if([delegate_ respondsToSelector:@selector(acrAPIErrorDidOccur:)])
    [delegate_ acrAPIErrorDidOccur: error];

  [self finishedRun];
}

@end
