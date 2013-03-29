//
//  ADTClient.m
//  ADTClient
//
//  Created by Marshall Beddoe on 3/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/NSKeyValueObserving.h>
#import <AVFoundation/AVFoundation.h>

#import "ADTBrowserController.h"

#import "ADTAudioRecorder.h"
#import "ADTAudioRecorderDelegate.h"
#import "ADTClient.h"
#import "ADTConstants.h"
#import "ADTLogging.h"
#import "ADTAudioACR.h"
#import "ADTRestAPI.h"
#import "ADTUtils.h"
#import "ADTLoadingView.h"

@interface ADTClient () <ADTAudioRecorderDelegate, ADTRestAPIDelegate, ADTBrowserControllerDelegate, ADTLoadingViewDelegate>

@property (getter=doRefresh)  BOOL              refresh;
@property (nonatomic, strong) ADTAudioRecorder* audioRecorder;
@property (nonatomic, strong) ADTRestAPI*       restAPI;
@property (nonatomic, strong) NSString*         appID;
@property (nonatomic, assign) NSUInteger        sampleDuration;
@property (nonatomic, strong) UIImageView*      spinner;
@property (nonatomic, strong) UIWebView*        infoPaneView;
@property (nonatomic, copy)   NSDictionary*     dimensions;
@property (nonatomic, strong) UIViewController* rootViewController;

@property (nonatomic, strong) ADTBrowserController* infoPaneController;

@property (nonatomic, assign) CGPoint           spinnerCoords;

@property (nonatomic, assign) BOOL              spinnerEnabled;
@property (nonatomic, assign) BOOL              kvoSetup;


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
                 appID:(NSString *)appID
             appSecret:(NSString *)appSecret
{
  if(self = [super init]) {
    _refresh        = refreshFlag;
    _delegate       = delegate;
    _ifa            = [self getAdvertiserIdentifier];
    _sampleDuration = ADT_SAMPLE_SECONDS;
    _appID          = appID;
    _restAPI        = [[ADTRestAPI alloc] initWithDelegate:self
                                                  andAppId:appID
                                              andAppSecret:appSecret
                                                   andUDID:_ifa];

    _audioRecorder = [[ADTAudioRecorder alloc] initWithDelegate:self];

    _infoPaneView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];

    // make sure allocations successful, bail otherwise.
    if(!_restAPI) {
      ADTLogError(@"ADTClient initWithDelegate failed..");
      return nil;
    }
  }

  return self;
}

#pragma mark -
#pragma mark Setup Audio Session

- (BOOL)setupAudioSession
{
  // Set the audio session category to play and record to enable the microphone..
  NSError *audioSessionError = nil;
  BOOL result = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                                       error: &audioSessionError];
  if(!result) {
    ADTLogError(@"Error setting AVAudioSession category to PlayAndRecord: %@", audioSessionError);
    return NO;
  }

  // in play and record, have to force audio to the main speaker
  UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
  AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
                          sizeof(audioRouteOverride), &audioRouteOverride);

  self.didAudioSessionSetup = YES;

  return YES;
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

  // setup audio session if necessary
  if(self.didAudioSessionSetup == NO) {
    NSLog(@"Setting up audio session");
    if([self setupAudioSession] == NO) {
      return NO;
    }
  }

  self.running = YES;

  if(self.spinner) {
    [self enableSpinner];
  }

  [self setupKVO];

  return [self startProcess];
}

- (BOOL) stop
{
  if(self.isRunning) {
    if(self.audioRecorder.isRecording)
      [self.audioRecorder stop];

    if(self.restAPI.isLoading)
      [self.restAPI cancel];

    if(self.spinner) {
      [self disableSpinner];
    }

    self.running = NO;

    return YES;
  }

  return NO;
}

#pragma mark -
#pragma mark Setup Spinner

- (void)showSpinner:(CGPoint)pos rootViewController:(UIViewController *)rootViewController
{
  self.spinnerCoords = pos;

  self.rootViewController = rootViewController;

  self.spinner = [[UIImageView alloc] initWithFrame:CGRectMake(self.spinnerCoords.x,self.spinnerCoords.y,20,20)];
  self.spinner.userInteractionEnabled = YES;
  self.spinner.image = [UIImage imageNamed:@"ADTIcon.png"];

  [self.spinner sizeToFit];

  self.spinner.hidden = YES;

  self.spinnerEnabled = YES;

  // Setup spinner to be tapped
  UITapGestureRecognizer *singleFingerTap =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(openInfoPane:)];

  [self.spinner addGestureRecognizer:singleFingerTap];

  CABasicAnimation *theAnimation;
  theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
  theAnimation.duration=0.75;
  theAnimation.repeatCount=HUGE_VALF;
  theAnimation.autoreverses=YES;
  theAnimation.removedOnCompletion = NO;
  theAnimation.fillMode = kCAFillModeForwards;
  theAnimation.fromValue=@1.0f;
  theAnimation.toValue = @0.0f;

  [[self.spinner layer] addAnimation:theAnimation forKey:@"animateOpacity"];

  [self.rootViewController.view addSubview:self.spinner];
}

- (void)enableSpinner
{
  self.spinnerEnabled = YES;

  [self startSpinner];
}

- (void)disableSpinner
{
  self.spinnerEnabled = NO;
  [self stopSpinner];
}

#pragma mark -
#pragma mark Checks for available ad unit with dimensions

- (BOOL)hasAdForWidth:(NSInteger)width height:(NSInteger)height
{
  if(!self.dimensions)
    return NO;

  NSString *key = [NSString stringWithFormat:@"%dx%d", width, height];

  if(self.dimensions[key])
    return YES;

  return NO;
}

#pragma mark -
#pragma mark Show Information Pane when Spinner Tapped

- (void)openInfoPane:(UITapGestureRecognizer *)recognizer
{
  // notify delegate that the info pane is about to open
  if([self.delegate respondsToSelector:@selector(ADTWillPresentInfoPaneView:)])
    [self.delegate ADTWillPresentInfoPaneView:self];

  NSURL *url = [NSURL URLWithString:
                [NSString stringWithFormat:@"http://infopane.adtonik.net/infoPane?ifa=%@&appID=%@", self.ifa, self.appID]];

  self.infoPaneController = [[ADTBrowserController alloc] initWithURL:url delegate:self];

  self.infoPaneController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

  [self.infoPaneController startLoading];

  [self showLoadingIndicator];
}

#pragma mark -
#pragma mark Start Spinner upon Activation

- (void) startSpinner {
  if(self.spinner && self.spinnerEnabled) {
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    self.spinner.alpha = 1.0;
  }
}

- (void) stopSpinner {
  if(self.spinner) {
    [self.spinner stopAnimating];
    self.spinner.hidden = YES;
    self.spinner.alpha = 0.0;
  }
}

#pragma mark -
#pragma mark Start the ACR Process

- (BOOL)startProcess
{
  [self startSpinner];

  // this will return false if in the middle of a phone call,
  // stop the spinner and requeue the process
  if([self.audioRecorder record:self.sampleDuration] == NO) {
    [self stopSpinner];
    [self finishedRun];
  }

  return YES;
}

#pragma mark -
#pragma mark Finish ACR Process

- (void)finishedRun
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
                                                selector:@selector(startProcess)
                                                userInfo:nil
                                                 repeats:NO];

  [runLoop addTimer:refreshTimer forMode:NSRunLoopCommonModes];
  [runLoop run];
}

#pragma mark -
#pragma mark Run ACR Algorithm on Audio File

- (void)runAlgorithm:(NSString *) filename
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
    NSString *identifier;
  // check method override in delegate
  if([self.delegate respondsToSelector:@selector(ADTAdvertiserIdentifier)]) {
      identifier = [self.delegate ADTAdvertiserIdentifier];
  } else {
      identifier = ADTAdvertisingIdentifier();
  }

  if(!identifier) {
    [NSException raise:@"Unable to get AdvertiserIdentifier"
                format:@"non-nil AdvertiserIdentifier required to use ADTClient, " \
                        "implement ADTAdvertiserIdentifier in the delegate"];
  }

  return identifier;
}

#pragma mark -
#pragma mark ACRAudioRecorder Delegate Methods

- (void)recorderFinished:(NSURL *)filename successfully:(BOOL)flag
{
  [self stopSpinner];

  if(!self.isRunning)
    return;

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
  [self stopSpinner];
  
  ADTLogInfo(@"ACR process ending: recorderFinished experienced and error..");

  self.running = NO;
  self.error = [NSError errorWithDomain:kADTClientErrorDomain code:kADTAudioError userInfo:nil];
}

#pragma mark -
#pragma mark ADTRestAPI Delegate Methods

- (void)restAPIDidReceiveResponse:(NSDictionary *)results successfully:(BOOL)flag
{
  if(!self.isRunning)
    return;

  // if adSizes available, save it, else nuke it
  if(results[@"adSizes"]) {
    self.dimensions = results[@"adSizes"];
  } else {
    self.dimensions = nil;
  }

  if(flag) {
    // Notify delegate that an ad is now available for this device
    if([results[@"hasAd"] boolValue] == YES) {

      if([self.delegate respondsToSelector:@selector(ADTClientDidReceiveAd:)]) {
        [self.delegate ADTClientDidReceiveAd:self];
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

#pragma mark -
#pragma mark Info Pane Delegate Methods

- (void)dismissBrowserController:(ADTBrowserController *)browserController
{
  [self dismissBrowserController:browserController animated:YES];
}

- (void) dismissBrowserController:(ADTBrowserController *)browserController animated:(BOOL)animated
{
  [browserController stopLoading];

  [self.rootViewController dismissViewControllerAnimated:animated completion:nil];

  if ([self.delegate respondsToSelector:@selector(ADTDidDismissInfoPaneView:)])
    [self.delegate ADTDidDismissInfoPaneView:self];
}

- (void)browserControllerDidFinishLoad:(ADTBrowserController *)browserController
{
  UIViewController *presentingViewController = self.rootViewController;
  UIViewController *presentedViewController;

  [self hideLoadingIndicator];

  if ([presentingViewController respondsToSelector:@selector(presentedViewController)]) {
    // For iOS 5 and above.
    presentedViewController = presentingViewController.presentedViewController;
  } else {
    // Prior to iOS 5, the modalViewController property holds the presented view controller.
    presentedViewController = presentingViewController.modalViewController;
  }

  // If the browser controller is already on-screen, don't try to present it again, or an
  // exception will be thrown (iOS 5 and above).
  if (presentedViewController == browserController) return;

  [self.rootViewController presentModalViewController:browserController animated:YES];
}

- (void)browserControllerWillLeaveApplication:(ADTBrowserController *)browserController
{
  if([self.delegate respondsToSelector:@selector(ADTWillLeaveApplication:)])
    [self.delegate ADTWillLeaveApplication:self];
}

#pragma mark -
#pragma mark ADTLoadingView Delegate Methods

- (void)showLoadingIndicator
{
  [ADTLoadingView presentOverlayInWindow:self.rootViewController.view.window animated:NO delegate:self];
}

- (void)hideLoadingIndicator
{
  UIWindow *window = self.rootViewController.view.window;

  [ADTLoadingView dismissOverlayFromWindow:window animated:NO];
}

- (void)overlayCanceled
{
  [self.infoPaneController stopLoading];

  [self hideLoadingIndicator];

  if([self.delegate respondsToSelector:@selector(ADTDidDismissInfoPaneView:)])
    [self.delegate ADTDidDismissInfoPaneView:self];
}

#pragma mark -
#pragma mark Handle KVO Events

- (void)setupKVO
{
  if(self.kvoSetup == YES)
    return;

  // when isRunning is set to NO
  [self addObserver:self forKeyPath:@"running" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];

  // when error is set
  [self addObserver:self forKeyPath:@"error" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];

  self.kvoSetup = YES;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if([keyPath isEqual:@"running"]) {

    // is isRunning set to NO, call delegate finished method
    if(self.isRunning == NO && change[@"new"] != change[@"old"]) {
      [self stopSpinner];
      
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

@end
