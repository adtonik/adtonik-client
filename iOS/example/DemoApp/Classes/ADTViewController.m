//
//  ADTViewController.m
//  DemoApp
//
//  Created by Marshall Beddoe on 4/30/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTViewController.h"
#import "ADTClient.h"
#import "ADTLoadAdDelegate.h"
#import "ADTLoadAd.h"

@interface ADTViewController () <ADTClientDelegate, ADTLoadAdDelegate>

@property (nonatomic, strong) ADTClient* adtonik;
@property (nonatomic, copy)   NSString*  liveTitle;
@property (nonatomic, strong) ADTLoadAd* loadAd;

@property (nonatomic, strong) IBOutlet UIWebView* webView;

@end

@implementation ADTViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.adtonik = [[ADTClient alloc] initWithDelegate:self doRefresh:YES andAppID:@"ADTDemoApp" andAppSecret:@"ADTDemoApp"];
  self.loadAd = [[ADTLoadAd alloc] initWithDelegate:self andUDID:self.adtonik.ifa];

  // load spinner on our view. Apple requires a visual notification when mic is activated.
  [self.adtonik showSpinnerAtX:5 andY:65];

  // start it up
  [self.adtonik start];

  UIColor *backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bg.png"]];
  self.view.backgroundColor = backgroundColor;

  self.webView.opaque = NO;
  self.webView.backgroundColor = [UIColor clearColor];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetView) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)resetView
{
  [self.webView loadHTMLString:@"" baseURL:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation == UIDeviceOrientationPortrait);
  } else {
    return NO;
  }
}

#pragma mark -
#pragma mark Required Delegate Methods

- (void) ADTClientDidReceiveMatch:(NSDictionary *)results
{
  NSLog(@"%@", results);
}

/**
 called when ad is ready for device
 */
- (void)ADTClientDidReceiveAd
{
  NSLog(@"LOADING AD FROM AD SERVER");
  [self.loadAd loadAd];
}

/**
 called when ad with dimensions is ready for device
 */
- (void)ADTClientDidReceiveAdsWithDimensions:(NSDictionary *)dimensions
{
  // check dimensions to do ad request in proper ad unit
}

/**
 called when ADTClient experiences an error
 */
- (void)ADTClientErrorDidOccur:(NSError *)error
{
  NSLog(@"ADTClient error occurred: %@", error);
}

/**
 called when ADTClient is completed
 */
- (void)ADTClientDidFinishSuccessfully
{
  NSLog(@"ACR Complete!");
}

/**
 view controller for presenting modal info pane and spinner
 */
- (UIViewController *) viewControllerForPresentingModalView
{
  return self;
}

#pragma mark -
#pragma mark Load Ad Delegates

- (void)ADTLoadAdDidReceiveAd:(NSString *)markup
{
  [self.webView loadHTMLString:markup baseURL:[NSURL URLWithString:@"http://api.adtonik.net"]];
}

@end
