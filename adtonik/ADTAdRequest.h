//
//  ADTAdRequest.h
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/15/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ADTAdRequestDelegate;

@interface ADTAdRequest : NSObject

@property (nonatomic, weak) id<ADTAdRequestDelegate> delegate;
@property (nonatomic, assign, getter=isLoading) BOOL loading;

+ (ADTAdRequest *) request;

- (void)requestAd:(CGSize)size appID:(NSString *)appID;

@end

@protocol ADTAdRequestDelegate <NSObject>

@required

- (void)didReceiveAdResponse:(NSData *)data;
- (void)didFailWithError:(NSError *)error;

@end
