//
//  ADTRestAPI.h
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/24/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSJSONSerialization.h>

#import "ADTRestAPIDelegate.h"

@interface ADTRestAPI : NSObject

@property (getter=isLoading) BOOL loading;
@property (nonatomic, assign) NSUInteger refreshTimer;

- (id) initWithDelegate:(id<ADTRestAPIDelegate>)delegate
               andAppId:(NSString *)appId
           andAppSecret:(NSString *)appSecret
                andUDID:(NSString *)udid;

- (NSURL *) apiURL:(NSString *)URL;

- (BOOL) queryWithFingerprints:(NSSet *)fingerprints andVersion:(NSString *)acrVersion;

- (void) cancel;

@end
