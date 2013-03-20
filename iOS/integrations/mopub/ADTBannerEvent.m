//
//  ADTBannerEvent.m
//  MoPubExample
//
//  Created by Marshall A. Beddoe on 2/14/13.
//  Copyright (c) 2013 Marshall A. Beddoe. All rights reserved.
//

#import "ADTBannerEvent.h"
#import "ADTUtils.h"

#ifndef kAdTonikAppID
#error define kAdTonikAppID with your appid
#endif

@interface ADTBannerEvent () <ADTAdViewDelegate>

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) ADTAdView* adtonikAdView;

@end

@implementation ADTBannerEvent

- (void) requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info
{
  NSLog(@"Requesting AdTonik banner.");

  UIViewController *rootViewController = [self.delegate viewControllerForPresentingModalView];

  self.adtonikAdView = [[ADTAdView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                                  appID:kAdTonikAppID
                                                 adSize:size
                                     rootViewController:rootViewController];

  self.adtonikAdView.delegate = self;

  ADTAdRequest *request = [ADTAdRequest request];

  [self.adtonikAdView loadAdRequest:request];
}

#pragma mark -
#pragma mark ADTAdView Delegate Methods

- (void)adViewDidFinishRequest:(ADTAdView *)adView
{
  NSLog(@"Successfully loaded adtonik banner.");

  [self.delegate bannerCustomEvent:self didLoadAd:adView];
}

- (void)adView:(ADTAdView *)adView didFailRequestWithError:(NSError *)error
{
  NSLog(@"Failed to load adtonik banner.");

  [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
}

- (void)adViewWillPresentScreen:(ADTAdView *)adView
{
  NSLog(@"AdTonik banner will present screen.");

  [self.delegate bannerCustomEventWillBeginAction:self];
}

- (void)adViewWillDismissScreen:(ADTAdView *)adView
{
  NSLog(@"AdTonik banner will dismiss screen.");

  [self.delegate bannerCustomEventDidFinishAction:self];
}

- (void)adViewWillLeaveApplication:(ADTAdView *)adView
{
  NSLog(@"AdTonik banner will leave application.");

  [self.delegate bannerCustomEventWillLeaveApplication:self];
}

@end
