//
//  ADTLoadingView.m
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/18/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import "ADTLoadingView.h"
#import "ADTLogging.h"

@interface ADTLoadingView ()

@property (nonatomic, strong) UIButton*                closeButton;
@property (nonatomic, assign) CGPoint                  closeButtonCenter;
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, weak) id<ADTLoadingViewDelegate> delegate;

@end

@implementation ADTLoadingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
  
    if(self) {
      self.opaque = NO;
      self.alpha = 0.0;

      _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
      _closeButton.alpha = 0.0;
      _closeButton.hidden = YES;
      
      [_closeButton addTarget:self
                       action:@selector(pressedCloseButton)
             forControlEvents:UIControlEventTouchUpInside];
      
      UIImage *image = [UIImage imageNamed:@"ADTCloseButton.png"];
      
      [_closeButton setImage:image forState:UIControlStateNormal];
      [_closeButton sizeToFit];
      
      _closeButtonCenter = CGPointMake(self.bounds.size.width - 6.0 - CGRectGetMidX(_closeButton.bounds),
                                       6.0 + CGRectGetMidY(_closeButton.bounds));
      _closeButton.center = _closeButtonCenter;
      
      [self addSubview:_closeButton];
      
      _activityIndicator = [[UIActivityIndicatorView alloc]
                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
      
      [_activityIndicator sizeToFit];
      [_activityIndicator startAnimating];
      _activityIndicator.center = self.center;
      _activityIndicator.frame = CGRectIntegral(_activityIndicator.frame);
      
      [self addSubview:_activityIndicator];
    }
  
    return self;
}

- (void)layoutSubviews
{
  [self updateCloseButtonPosition];
}

- (void)updateCloseButtonPosition
{
  CGPoint originalCenter = self.closeButtonCenter;
  CGPoint center = originalCenter;
  BOOL statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
  CGFloat statusBarOffset = (statusBarHidden) ? 0.0 : 20.0;
  
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  switch (orientation) {
    case UIInterfaceOrientationLandscapeLeft:
      center.x = CGRectGetMaxX(self.bounds) - originalCenter.x + statusBarOffset;
      center.y = originalCenter.y;
      break;
    case UIInterfaceOrientationLandscapeRight:
      center.x = originalCenter.x - statusBarOffset;
      center.y = CGRectGetMaxY(self.bounds) - originalCenter.y;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      center.x = CGRectGetMaxX(self.bounds) - originalCenter.x;
      center.y = CGRectGetMaxY(self.bounds) - originalCenter.y - statusBarOffset;
      break;
    default:
      center.y = originalCenter.y + statusBarOffset;
      break;
  }
  
  self.closeButton.center = center;
}

- (void)pressedCloseButton
{
  if ([_delegate respondsToSelector:@selector(overlayCanceled)]) {
    [_delegate overlayCanceled];
  }
}

+ (void)presentOverlayInWindow:(UIWindow *)window
                      animated:(BOOL)animated
                      delegate:(id<ADTLoadingViewDelegate>)delegate
{
  if ([self windowHasExistingOverlay:window]) {
    ADTLogWarn(@"This window is already displaying a progress overlay view.");
    return;
  }

  ADTLoadingView *overlay = [[ADTLoadingView alloc] initWithFrame:window.bounds];
  
  overlay.delegate = delegate;

  [window addSubview:overlay];
  
  overlay.alpha = 1.0;
  
  [overlay performSelector:@selector(enableCloseButton)
                withObject:nil
                afterDelay:4.0];
}

+ (void)dismissOverlayFromWindow:(UIWindow *)window animated:(BOOL)animated
{
  ADTLoadingView *overlay = [self overlayForWindow:window];

  overlay.alpha = 0.0;
  [overlay removeFromSuperview];
}

- (void)enableCloseButton
{
  self.closeButton.hidden = NO;
  
  [UIView beginAnimations:nil context:nil];
  self.closeButton.alpha = 1.0;
  [UIView commitAnimations];
}

+ (BOOL)windowHasExistingOverlay:(UIWindow *)window
{
  return !![self overlayForWindow:window];
}

#pragma mark -
#pragma mark Returns ADTLoadingView in Window

+ (ADTLoadingView *)overlayForWindow:(UIWindow *)window
{
  NSArray *subviews = window.subviews;
  
  for(UIView *view in subviews) {
    if([view isKindOfClass:[ADTLoadingView class]]) {
      return (ADTLoadingView *)view;
    }
  }
  
  return nil;
}

@end
