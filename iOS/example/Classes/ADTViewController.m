//
//  ADTViewController.m
//  DemoApp
//
//  Created by Marshall Beddoe on 4/30/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTViewController.h"
#import "ADTClient.h"
#import "ADTAdView.h"

@interface ADTViewController () <ADTClientDelegate>

@property (nonatomic, strong) ADTClient* adtonik;
@property (nonatomic, strong) ADTAdView* adtAdView;

@property (nonatomic, strong) IBOutlet UIImageView*  adView;

@end

@implementation ADTViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.adtonik = [[ADTClient alloc] initWithDelegate:self doRefresh:YES appID:@"ADTDemoApp" appSecret:@"ADTDemoApp"];
  self.adtAdView = [[ADTAdView alloc] initWithFrame:CGRectMake(0,0,320,50) appID:@"ADTDemoApp" adSize:CGSizeMake(320,50) rootViewController:self];
    
  self.adView.backgroundColor = [UIColor grayColor];
  self.adView.opaque = YES;
  
  [self.adView addSubview:self.adtAdView];
  
  // load spinner on our view. Apple requires a visual notification when mic is activated.
  [self.adtonik showSpinner:CGPointMake(5, 65) rootViewController:self];

  // start it up
  [self.adtonik start];
  
  [self.adtAdView loadAdRequest:[ADTAdRequest request]];

  UIColor *backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"bg.png"]];
  self.view.backgroundColor = backgroundColor;
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
- (void)ADTClientDidReceiveAd:(ADTClient *)adtonik
{
  ADTAdRequest *adRequest = [ADTAdRequest request];
  
  [self.adtAdView loadAdRequest:adRequest];

  NSLog(@"LOADING AD FROM AD SERVER");
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

@end
