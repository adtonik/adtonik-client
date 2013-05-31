//
//  ADTLoadingView.h
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/18/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ADTLoadingViewDelegate;

@interface ADTLoadingView : UIView

+ (void)presentOverlayInWindow:(UIWindow *)window
                      animated:(BOOL)animated
                      delegate:(id<ADTLoadingViewDelegate>)delegate;

+ (void)dismissOverlayFromWindow:(UIWindow *)window animated:(BOOL)animated;

@end

@protocol ADTLoadingViewDelegate <NSObject>

@optional

- (void)overlayCanceled;

@end
