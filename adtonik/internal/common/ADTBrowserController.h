//
//  ADTBrowserController.h
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/8/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ADTBrowserControllerDelegate;

@interface ADTBrowserController : UIViewController <UIWebViewDelegate>

- (id) initWithURL:(NSURL *)URL delegate:(id<ADTBrowserControllerDelegate>)delegate;

- (void) startLoading;
- (void) stopLoading;

@end

@protocol ADTBrowserControllerDelegate <NSObject>

@required
- (void)dismissBrowserController:(ADTBrowserController *)browserController;
- (void)dismissBrowserController:(ADTBrowserController *)browserController animated:(BOOL)animated;

@optional
- (void)browserControllerDidFinishLoad:(ADTBrowserController *)browserController;
- (void)browserControllerWillLeaveApplication:(ADTBrowserController *)browserController;
@end