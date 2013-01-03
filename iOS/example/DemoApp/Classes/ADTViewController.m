//
//  ADTViewController.m
//  DemoApp
//
//  Created by Marshall Beddoe on 4/30/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTViewController.h"

@implementation ADTViewController

@synthesize audioACR = audioACR_;
@synthesize webView = webView_;
@synthesize liveTitle = liveTitle_;

- (void)viewDidLoad
{
  [super viewDidLoad];

  ADTAudioACR *newAudioACR = [[ADTAudioACR alloc] initWithDelegate:self refresh:YES];

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
  [audioACR_ release];
  [webView_ release];
  [liveTitle_ release];
  
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
  [audioACR_ release];
  [webView_ release];
  [liveTitle_ release];
  
  [super dealloc];
}

- (void) resetView {
  [webView_ loadHTMLString:@"" baseURL:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation == UIDeviceOrientationPortrait);
  } else {
    return NO;
  }
}

- (NSString *) acrAppId {
  return @"ADTDemoApp";
}

- (NSString *) acrAppSecret {
  return @"ADTDemoApp";
}

- (void) acrAPIReceivedResults: (NSDictionary *) results successfully:(BOOL) flag {  
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
      [webView_  loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
  }
}

- (void) acrAPIErrorDidOccur: (NSString *) error {
  NSLog(@"Encountered API ERROR %@", error);
}

- (void) acrAudioProcessingError: (NSString *) error {
  NSLog(@"Encountered audio processing error %@", error);
}

- (void) acrComplete {
  NSLog(@"ACR Complete!");
}

@end