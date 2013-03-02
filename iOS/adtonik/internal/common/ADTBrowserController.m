//
//  ADTBrowserController.m
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/8/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import "ADTBrowserController.h"
#import "ADTLogging.h"

@interface ADTBrowserController () <UIAlertViewDelegate>

@property (nonatomic, copy) NSURL* URL;
@property (nonatomic, weak) id<ADTBrowserControllerDelegate> delegate;
@property (nonatomic, assign) BOOL hasLeftApplication;
@property (nonatomic, assign) NSInteger loadCount;
@property (nonatomic, strong) UIActivityIndicatorView *webSpinner;

@property (nonatomic, strong) IBOutlet UIWebView* webView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* backButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* forwardButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* webSpinnerItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* refreshButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* safariButton;

- (IBAction) close;

@end

@implementation ADTBrowserController

- (id) initWithURL:(NSURL *)URL delegate:(id<ADTBrowserControllerDelegate>)delegate
{
  self = [super initWithNibName:@"ADTBrowserController" bundle:nil];
  
  if(self) {
    _delegate = delegate;
    _URL = [URL copy];
    
    _webSpinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
		[_webSpinner sizeToFit];
		_webSpinner.hidesWhenStopped = YES;
  }
  
  return self;
}

- (void) startLoading
{
  [self view];

  self.hasLeftApplication = NO;
  self.webView.delegate = self;
  self.loadCount = 0;

  [self.webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
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

- (IBAction) close
{
  if (self.delegate) {
    [self.delegate dismissBrowserController:self];
  } else {
    [self dismissFromPresentingViewControllerAnimated:YES];
  }
}

#pragma mark -
#pragma mark Handling Opening URLs in External Browser

- (BOOL) shouldLeaveApplicationForURL:(NSURL *)url
{
  NSArray *schemes = @[@"http", @"https"];
    
  if([schemes containsObject:url.scheme] == NO) {
    return [[UIApplication sharedApplication] canOpenURL:url];
  }
  
  return NO;
}

- (void)leaveApplicationForURL:(NSURL *)url
{
  self.hasLeftApplication = YES;
  
  BOOL onScreen = !!self.view.window;
  
  if(onScreen) {
    [self dismissBrowserAndOpenURL:url];
  } else {
    if([self.delegate respondsToSelector:@selector(browserControllerWillLeaveApplication:)]) {
      [self.delegate browserControllerWillLeaveApplication:self];
    }
    [[UIApplication sharedApplication] openURL:url];
  }
}

- (void)dismissBrowserAndOpenURL:(NSURL *)url
{
  if ([self.delegate respondsToSelector:@selector(browserControllerWillLeaveApplication:)]) {
    [self.delegate browserControllerWillLeaveApplication:self];
  }
  
  // Ensure that the browser controller gets dismissed even if its delegate is set to nil.
  if (self.delegate) {
    [self.delegate dismissBrowserController:self animated:NO];
  } else {
    [self dismissFromPresentingViewControllerAnimated:NO];
  }
  
  [[UIApplication sharedApplication] openURL:url];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.backButton.image = [UIImage imageNamed:@"ADTBack.png"];
  self.backButton.title = nil;
  self.forwardButton.image = [UIImage imageNamed:@"ADTForward.png"];
  self.forwardButton.title = nil;
  self.webSpinnerItem.customView = self.webSpinner;
	self.webSpinnerItem.title = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  self.backButton.enabled = self.webView.canGoBack;
  self.forwardButton.enabled = self.webView.canGoForward;
  self.refreshButton.enabled = NO;
}

#pragma mark -
#pragma mark UIWebView Delegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  ADTLogInfo(@"Browser loading url: %@", request.URL);
  
  if ([self shouldLeaveApplicationForURL:request.URL]) {
    [self leaveApplicationForURL:request.URL];
    return NO;
  } else {
    return YES;
  }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
  self.loadCount++;
  
  self.refreshButton.enabled = YES;
  [self.webSpinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  self.loadCount--;
  
  self.backButton.enabled = self.webView.canGoBack;
  self.forwardButton.enabled = self.webView.canGoForward;
  self.refreshButton.enabled = YES;

  [self.webSpinner stopAnimating];

  if(self.loadCount > 0)
    return;
  
  if(self.hasLeftApplication)
    return;
  
  if ([self.delegate respondsToSelector:@selector(browserControllerDidFinishLoad:)]) {
    [self.delegate browserControllerDidFinishLoad:self];
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
  self.loadCount--;
  
  self.backButton.enabled = self.webView.canGoBack;
  self.forwardButton.enabled = self.webView.canGoForward;
  [self.webSpinner stopAnimating];
  self.refreshButton.enabled = YES;

  // Ignore innocuous errors: NSURLErrorDomain, Frame Load Interrupted
  if (error.code == NSURLErrorCancelled) return;
  if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) return;

  ADTLogError(@"Browser experienced an error: %@", [error localizedDescription]);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

#pragma mark - WebView Button Actions

- (IBAction)refresh
{
	[self.webView reload];
}

- (IBAction)back
{
  [self.webView goBack];
  self.backButton.enabled = self.webView.canGoBack;
  self.forwardButton.enabled = self.webView.canGoForward;
}

- (IBAction)forward
{
  [self.webView goForward];
  self.backButton.enabled = self.webView.canGoBack;
  self.forwardButton.enabled = self.webView.canGoForward;
}

- (IBAction)safari
{
  UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Open in Safari"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    
  [message show];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
  
  if([title isEqualToString:@"OK"]) {    
    [self leaveApplicationForURL:self.webView.request.URL];
  }
}

@end
