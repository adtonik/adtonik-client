//
//  ADTRestEnvelope.m
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/25/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <CommonCrypto/CommonHMAC.h>

#import "ADTRestEnvelope.h"
#import "ADTClient.h"
#import "ADTLogging.h"
#import "ADTConstants.h"

@interface ADTRestEnvelope ()

@property (nonatomic, copy) NSString* appId;
@property (nonatomic, copy) NSString* appSecret;

@end

@implementation ADTRestEnvelope

#pragma mark -
#pragma mark Envelope Version

+ (NSString *)envelopeVersion
{
  return @"1.0.0";
}

#pragma mark -
#pragma mark Envelope Construction

+ (NSData *)messageWithData:(id)data
                      state:(NSDictionary *)state
                      appId:(NSString *)appId
                  appSecret:(NSString *)appSecret
                 acrVersion:(NSString *)acrVersion
                    andUDID:(NSString *)udid
{

  time_t unixTime = (time_t) [[NSDate date] timeIntervalSince1970];

  NSDictionary *message = @{@"timestamp": @(unixTime),
                           @"type": @"request",
                           @"envelopeVersion": [ADTRestEnvelope envelopeVersion],
                           @"sdkVersion": kADTSDKVersion,
                           @"acrVersion": acrVersion,
                           @"udid": udid,
                           @"appID": appId,
                           @"state": state,
                           @"data": data};
  
  NSError *error = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];
  
  if(error) {
    ADTLogError(@"error serializing %@ - %@", message, error);
    return nil;
  }

  return jsonData;
}

#pragma mark -
#pragma mark Envelope Validation

+ (BOOL)validEnvelope:(NSDictionary *)envelope
{
  // validate required envelope fields
  if(!envelope[@"status"] && envelope[@"timestamp"] && envelope[@"data"] &&
     envelope[@"refreshTimer"] && envelope[@"envelopeVersion"] && envelope[@"match"]) {
    return NO;
  }
  
  // validate envelope version
  if(![envelope[@"envelopeVersion"] isEqualToString:[ADTRestEnvelope envelopeVersion]]) {
    return NO;
  }

  return [envelope[@"type"] isEqualToString:@"response"];
}

#pragma mark -
#pragma mark Check for successful response

+ (BOOL)successResponse:(NSDictionary *)envelope
{  
  if(![ADTRestEnvelope validEnvelope:envelope]) {
    return NO;
  }

  return [envelope[@"status"] isEqualToString:@"success"];
}

#pragma mark -
#pragma mark HMAC Message Signing

+ (NSString *)signMessage:(NSData *)message
                withAppID:(NSString *)appID
             andAppSecret:(NSString *)appSecret
{
  char *p;
  CCHmacContext ctx;
  unsigned char mac[CC_SHA1_DIGEST_LENGTH];
  char hexmac[2 * CC_SHA1_DIGEST_LENGTH + 1];

  const char *data = [message bytes];

  NSArray *keyValues = @[appID, appSecret];
  const char *key = [[keyValues componentsJoinedByString:@":"]
                     cStringUsingEncoding:NSASCIIStringEncoding];


  CCHmacInit(&ctx, kCCHmacAlgSHA1, key, strlen(key));
  CCHmacUpdate(&ctx, data, [message length]);
  CCHmacFinal(&ctx, mac);

  p = hexmac;

  for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
    snprintf(p, 3, "%02x", mac[i]);
    p += 2;
  }

  return @(hexmac);
}

@end
