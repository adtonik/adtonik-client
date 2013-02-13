//
//  ADTRestEnvelope.h
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/25/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSJSONSerialization.h>

@interface ADTRestEnvelope : NSObject;

+ (NSData *)messageWithData:(id)data
                       state:(NSDictionary *)state
                       appId:(NSString *)appId
                   appSecret:(NSString *)appSecret
                  acrVersion:(NSString *)version
                     andUDID:(NSString *)udid;


+ (NSString *)signMessage:(NSData *)message
                 withAppID:(NSString *)appID
              andAppSecret:(NSString *)appSecret;

+ (BOOL)validEnvelope:(NSDictionary *)envelope;
+ (BOOL)successResponse:(NSDictionary *)envelope;

+ (NSString *)envelopeVersion;

@end
