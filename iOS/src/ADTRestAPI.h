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

@interface ADTRestAPI : NSObject <NSURLConnectionDataDelegate> {
  NSString *appId_;
  NSString *appSecret_;
  NSString *udid_;

  NSURLConnection *conn_;
  NSMutableURLRequest *request_;
  NSMutableData *data_;
  NSDictionary *headers_;

  NSDictionary *response_;

  NSUInteger refreshTimer_;
  
  NSDictionary *state_;
  
  BOOL loading_;

  id<ADTRestAPIDelegate> delegate_;
}

@property (getter=isLoading) BOOL loading;

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appSecret;
@property (nonatomic, copy) NSString *udid;

@property (nonatomic, copy) NSDictionary *response;
@property (nonatomic, copy) NSDictionary *state;

@property (nonatomic, assign) NSUInteger timeout;
@property (nonatomic, assign) id <ADTRestAPIDelegate> delegate;
@property (nonatomic, assign) NSUInteger refreshTimer;

@property (nonatomic, retain) NSMutableURLRequest *request;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSDictionary *headers;

- (id) initWithDelegate: (id<ADTRestAPIDelegate>) delegate
               andAppId: (NSString *) appId
           andAppSecret: (NSString *) appSecret
                andUDID: (NSString *) udid;

- (NSURL *) apiURL: (NSString *) URL;

- (BOOL) queryWithFingerprints: (NSSet *) fingerprints andVersion: (NSString *) acrVersion;

- (void) cancel;

@end
