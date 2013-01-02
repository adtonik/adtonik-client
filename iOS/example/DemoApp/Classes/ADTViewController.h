//
//  ADTViewController.h
//  DemoApp
//
//  Created by Marshall Beddoe on 4/30/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ADTAudioACR.h"

@interface ADTViewController : UIViewController <ADTAudioACRDelegate> {
  UIWebView *webView_;
  ADTAudioACR *audioACR_;
  NSString *liveTitle_;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) ADTAudioACR *audioACR;
@property (nonatomic, copy) NSString *liveTitle;

@end
