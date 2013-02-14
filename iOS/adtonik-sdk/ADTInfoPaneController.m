//
//  ADTInfoPaneController.m
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/8/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import "ADTInfoPaneController.h"

@implementation ADTInfoPaneController

- (id) initWithDelegate:(id<ADTInfoPaneControllerDelegate>)delegate andAppID:(NSString *) appID andIFA:(NSString *)ifa
{
  self = [super initWithNibName:@"ADTInfoPane" bundle:nil];

  if(self) {
    _delegate = delegate;
    _ifa = ifa;
    _appID = appID;
  }

  return self;
}

- (void) startLoading
{
  [self view];

  self.webView.delegate = self;

  NSString *urlString = [NSString stringWithFormat:@"http://api.adtonik.net/infoPane/?ifa=%@&app=%@", self.ifa, self.appID];

  [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

- (void) stopLoading
{
  [self.webView stopLoading];
  self.webView.delegate = nil;
}

- (void)dismissFromPresentingViewControllerAnimated:(BOOL)animated
{
  UIViewController *presentingViewController;

  if ([self respondsToSelector:@selector(presentingViewController)]) {
    // For iOS 5 and above.
    presentingViewController = self.presentingViewController;
  } else {
    // Prior to iOS 5, the parentViewController property holds the presenting view controller.
    presentingViewController = self.parentViewController;
  }

#if NS_BLOCKS_AVAILABLE
  if ([presentingViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
    [presentingViewController dismissViewControllerAnimated:animated completion:nil];
    return;
  }
#endif

  [presentingViewController dismissModalViewControllerAnimated:animated];
}

- (IBAction) tapClosed
{
  if (self.delegate) {
    [self.delegate dismissInfoPaneController:self];
  } else {
    [self dismissFromPresentingViewControllerAnimated:YES];
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  [self.delegate infoPaneControllerDidFinishLoad:self];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

@end
