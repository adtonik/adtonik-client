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

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) ADTClient *audioACR;
@property (nonatomic, copy) NSString *liveTitle;
@property (nonatomic, strong) ADTLoadAd* loadAd;

@end

@implementation ADTViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  ADTClient *newAudioACR = [[ADTClient alloc] initWithDelegate:self doRefresh:YES andAppID:@"ADTDemoApp" andAppSecret:@"ADTDemoApp"];

  self.audioACR = newAudioACR;
  
  self.loadAd = [[ADTLoadAd alloc] initWithDelegate:self andUDID:self.audioACR.udid];

  // start it up
  [self.audioACR start];
  
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


- (void) resetView
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
  NSNumber *liveTV = results[@"live_tv"];

  NSLog(@"%@", results);
  
  if([liveTV intValue] == 1) {
    NSString *title = results[@"title"];
    NSString *subtitle = results[@"subtitle"];
    
    if([subtitle isKindOfClass:[NSNull class]] == NO) {
      title = [NSString stringWithFormat:@"%@ - %@", title, subtitle];
    }
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Live TV"
                                                      message:title
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    if([self.liveTitle isEqualToString:title]) {
      [message show];
    }
    
    self.liveTitle = title;
      
  }
}

- (void)ADTClientDidReceiveAd
{
  NSLog(@"LOADING AD FROM AD SERVER");
  [self.loadAd loadAd];
}

- (void)ADTClientErrorDidOccur:(NSError *)error
{
  NSLog(@"ADTClient error occurred: %@", error);
}

- (void)ADTClientDidFinishSuccessfully
{
  NSLog(@"ACR Complete!");
}

#pragma mark -
#pragma mark Load Ad Delegates

- (void)ADTLoadAdDidReceiveAd:(NSString *)markup
{
  [self.webView loadHTMLString:markup baseURL:[NSURL URLWithString:@"http://api.adtonik.net"]];
}

@end