//
//  ADTAdView.h
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/15/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ADTAdRequest.h"

@protocol ADTAdViewDelegate;

@interface ADTAdView : UIView

@property (nonatomic, weak) id<ADTAdViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame
               appID:(NSString *)appID
              adSize:(CGSize)adSize
  rootViewController:(UIViewController *)rootViewController;

- (void)loadAdRequest:(ADTAdRequest *)request;

@end

@protocol ADTAdViewDelegate <NSObject>

@optional

- (void)adViewDidFinishRequest:(ADTAdView *)adView;
- (void)adView:(ADTAdView *)adView didFailRequestWithError:(NSError *)error;
- (void)adViewWillPresentScreen:(ADTAdView *)adView;
- (void)adViewWillDismissScreen:(ADTAdView *)adView;
- (void)adViewWillLeaveApplication:(ADTAdView *)adView;

@end