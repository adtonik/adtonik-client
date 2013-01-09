//
//  ADTViewController.m
//  DemoApp
//
//  Created by Marshall Beddoe on 4/30/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTViewController.h"

@interface ADTViewController () <ADTAudioACRDelegate>

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) ADTAudioACR *audioACR;
@property (nonatomic, copy) NSString *liveTitle;

@end

@implementation ADTViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  ADTAudioACR *newAudioACR = [[ADTAudioACR alloc] initWithDelegate:self doRefresh:YES andAppID:@"ADTDemoApp" andAppSecret:@"ADTDemoApp"];

  self.audioACR = newAudioACR;
  [newAudioACR release];
  
  // start it up
  [self.audioACR start];
  
  UIColor *backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bg.png"]];
  self.view.backgroundColor = backgroundColor;
  [backgroundColor release];
  
  self.webView.opaque = NO;
  self.webView.backgroundColor = [UIColor clearColor];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetView) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
  [self.audioACR release];
  [self.webView release];
  [self.liveTitle release];
  
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
  [_audioACR release];
  [_webView release];
  [_liveTitle release];
  
  [super dealloc];
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

- (void) acrAPIDidReceiveMatch:(NSDictionary *)results matchedSuccessfully:(BOOL)flag
{
  if(flag == YES) {
    
    NSNumber *live_tv = [results objectForKey:@"live_tv"];
    
    if([live_tv intValue] == 1) {
      NSString *title = [results objectForKey:@"title"];
      NSString *subtitle = [results objectForKey:@"subtitle"];

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
      
      [message release];
      return;
    }
    
    NSString *url  = [results objectForKey:@"url"];

    if(url != NULL) {      
      [self.webView  loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
  }
}

- (void)acrAPIErrorDidOccur:(NSString *)error
{
  NSLog(@"Encountered API ERROR %@", error);
}

- (void)acrAudioProcessingError:(NSString *)error
{
  NSLog(@"Encountered audio processing error %@", error);
}

- (void)acrComplete
{
  NSLog(@"ACR Complete!");
}

@end