//
//  ADTInfoPaneController.h
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/8/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ADTInfoPaneControllerDelegate;

@interface ADTInfoPaneController : UIViewController <UIWebViewDelegate>

@property (nonatomic, copy) NSString* ifa;
@property (nonatomic, copy) NSString* appID;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* close;
@property (nonatomic, strong) IBOutlet UIWebView* webView;

@property (nonatomic, assign) id<ADTInfoPaneControllerDelegate> delegate;

- (id) initWithDelegate:(id<ADTInfoPaneControllerDelegate>)delegate andAppID:(NSString *) appID andIFA:(NSString *)ifa;

- (void) startLoading;
- (void) stopLoading;

- (IBAction) tapClosed;

@end

@protocol ADTInfoPaneControllerDelegate <NSObject>

@required
- (void)dismissInfoPaneController:(ADTInfoPaneController *)infoPaneController;
- (void)dismissInfoPaneController:(ADTInfoPaneController *)infoPaneController animated:(BOOL)animated;

@optional
- (void)infoPaneControllerDidFinishLoad:(ADTInfoPaneController *)infoPaneController;
- (void)infoPaneControllerWillLeaveApplication:(ADTInfoPaneController *)infoPaneController;
@end