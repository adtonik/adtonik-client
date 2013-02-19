//
//  ADTAdView.m
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/15/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import "ADTAdView.h"
#import "ADTAdRequest.h"
#import "ADTBrowserController.h"
#import "ADTLoadingView.h"

@interface ADTAdView () <ADTAdRequestDelegate, UIWebViewDelegate, ADTBrowserControllerDelegate, ADTLoadingViewDelegate>

@property (nonatomic, strong) UIWebView*            webView;
@property (nonatomic, strong) UIViewController*     rootViewController;
@property (nonatomic, assign) CGSize                adSize;
@property (nonatomic, copy)   NSString*             appID;
@property (nonatomic, strong) ADTBrowserController* browserController;

@end

@implementation ADTAdView

- (id)initWithFrame:(CGRect)frame
              appID:(NSString *)appID
             adSize:(CGSize)adSize
 rootViewController:(UIViewController *)rootViewController
{
  if(self = [super initWithFrame:frame]) {
    self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = YES;

    _appID = [NSString stringWithString:appID];
    _adSize = adSize;
    _rootViewController = rootViewController;

    CGRect webViewFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    _webView = [[UIWebView alloc] initWithFrame:webViewFrame];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.delegate = self;
    _webView.opaque = NO;
    
    if ([_webView respondsToSelector:@selector(allowsInlineMediaPlayback)]) {
      [_webView setAllowsInlineMediaPlayback:YES];
      [_webView setMediaPlaybackRequiresUserAction:NO];
    }

    [self addSubview:_webView];
  }
  
  return self;
}

- (void) loadAdRequest:(ADTAdRequest *)request
{
  request.delegate = self;

  [request requestAd:self.adSize appID:self.appID];
}

#pragma mark -
#pragma mark Checks if Link Opens in Browser View

- (BOOL)shouldOpenBrowserForURL:(NSURL *)URL
                 navigationType:(UIWebViewNavigationType)navigationType
{
  if (navigationType == UIWebViewNavigationTypeLinkClicked) {
    return YES;
  } else {
    return NO;
  }
}

#pragma mark -
#pragma mark Opens Browser View as Modal

- (void)openBrowserForURL:(NSURL *)URL
{  
  if([self.delegate respondsToSelector:@selector(adViewWillPresentScreen:)])
    [self.delegate adViewWillPresentScreen:self];

  [self.browserController stopLoading];
  self.browserController = [[ADTBrowserController alloc] initWithURL:URL delegate:self];
  
  self.browserController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  
  [self.browserController startLoading];
  
  [self showLoadingIndicator];
}

#pragma mark -
#pragma mark ADTAdRequest Delegate Methods

- (void)didReceiveAdResponse:(NSData *)data
{
  if([self.delegate respondsToSelector:@selector(adViewDidFinishRequest:)])
    [self.delegate adViewDidFinishRequest:self];

  [self.webView loadData:data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
}

- (void)didFailWithError:(NSError *)error
{
  if([self.delegate respondsToSelector:@selector(adView:didFailRequestWithError:)])
    [self.delegate adView:self didFailRequestWithError:error];
}

#pragma mark -
#pragma mark UIWebView Delegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  NSURL *URL __unused = [request URL];
  
  if ([self shouldOpenBrowserForURL:URL navigationType:navigationType]) {
    [self openBrowserForURL:URL];
    return NO;
  } else {
    return YES;
  }
}

#pragma mark -
#pragma mark Browser Controller Delegate Methods

- (UIViewController *)viewControllerForPresentingModalView
{
  return self.rootViewController;
}

- (void)dismissBrowserController:(ADTBrowserController *)browserController
{
  [self dismissBrowserController:browserController animated:YES];
}

- (void) dismissBrowserController:(ADTBrowserController *)browserController animated:(BOOL)animated
{
  [browserController stopLoading];
  
  [[self viewControllerForPresentingModalView] dismissViewControllerAnimated:animated completion:nil];
  
  if([self.delegate respondsToSelector:@selector(adViewWillDismissScreen:)])
    [self.delegate adViewWillDismissScreen:self];  
}

- (void)browserControllerDidFinishLoad:(ADTBrowserController *)browserController
{
  [self hideLoadingIndicator];
  
  UIViewController *presentingViewController = [self viewControllerForPresentingModalView];
  UIViewController *presentedViewController;
  
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
    
  [[self viewControllerForPresentingModalView] presentModalViewController:browserController animated:YES];
}

- (void)browserControllerWillLeaveApplication:(ADTBrowserController *)browserController
{
  [self hideLoadingIndicator];

  if([self.delegate respondsToSelector:@selector(adViewWillLeaveApplication:)])
    [self.delegate adViewWillLeaveApplication:self];
}

- (void)showLoadingIndicator
{
  [ADTLoadingView presentOverlayInWindow:self.window animated:NO delegate:self];
}

- (void)hideLoadingIndicator
{
  UIWindow *window = self.window ? self.window : [UIApplication sharedApplication].keyWindow;
  
  [ADTLoadingView dismissOverlayFromWindow:window animated:NO];
}

- (void)overlayCanceled
{
  [self.browserController stopLoading];

  [self hideLoadingIndicator];

  if([self.delegate respondsToSelector:@selector(adViewWillDismissScreen:)])
    [self.delegate adViewWillDismissScreen:self];
}

@end
