//
//  ADTRestEnvelope.m
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/25/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <CommonCrypto/CommonHMAC.h>

#import "ADTRestEnvelope.h"
#import "ADTAudioACR.h"
#import "ADTLogging.h"
#import "ADTConstants.h"

@interface ADTRestEnvelope ()

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appSecret;

@end

@implementation ADTRestEnvelope

#pragma mark -
#pragma mark Envelope Version

+ (NSString *) envelopeVersion
{
  return @"1.0.0";
}

#pragma mark -
#pragma mark Envelope Construction

+ (NSData *) messageWithData: (id) data
                       state: (NSDictionary *) state
                       appId: (NSString *) appId
                   appSecret: (NSString *) appSecret
                  acrVersion: (NSString *) acrVersion
                     andUDID: (NSString *) udid
{

  time_t unixTime = (time_t) [[NSDate date] timeIntervalSince1970];

  NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithLong:unixTime], @"timestamp",
                           @"request"                        , @"type",
                           [ADTRestEnvelope envelopeVersion] , @"envelopeVersion",
                           kAdTonikSDKVersion                , @"sdkVersion",
                           acrVersion                        , @"acrVersion",
                           udid                              , @"udid",
                           appId                             , @"appID",
                           state                             , @"state",
                           data                              , @"data", nil];
  
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

+ (BOOL) validEnvelope: (NSDictionary *) envelope
{
  // validate required envelope fields
  if(([envelope objectForKey:@"status"] &&
      [envelope objectForKey:@"timestamp"] &&
      [envelope objectForKey:@"data"] &&
      [envelope objectForKey:@"match"] &&
      [envelope objectForKey:@"refreshTimer"] &&
      [envelope objectForKey:@"envelopeVersion"]) == NO) {
    return NO;
  }

  // validate envelope version
  if(![[envelope objectForKey:@"envelopeVersion"]
       isEqualToString:[ADTRestEnvelope envelopeVersion]]) {
    return NO;
  }

  // make sure type is response
  if(![[envelope objectForKey:@"type"] isEqualToString:@"response"])
    return NO;

  return YES;
}

#pragma mark -
#pragma mark Check for successful response

+ (BOOL) successResponse: (NSDictionary *) envelope
{
  if([ADTRestEnvelope validEnvelope:envelope] == NO)
    return NO;

  if([[envelope objectForKey:@"status"] isEqualToString:@"success"] &&
     [[envelope objectForKey:@"match"] boolValue] == YES)
    return YES;
  else
    return NO;
}

#pragma mark -
#pragma mark HMAC Message Signing

+ (NSString *) signMessage: (NSData *) message
                 withAppID: (NSString *) appID
              andAppSecret: (NSString *) appSecret
{

  CCHmacContext    ctx;
  unsigned char    mac[ CC_SHA1_DIGEST_LENGTH ];
  char             hexmac[ 2 * CC_SHA1_DIGEST_LENGTH + 1 ];
  char             *p;

  const char *data = [message bytes];

  NSArray *keyValues = [NSArray arrayWithObjects:appID, appSecret, nil];
  const char *key  = [[keyValues componentsJoinedByString:@":"]
                      cStringUsingEncoding:NSASCIIStringEncoding];


  CCHmacInit(&ctx, kCCHmacAlgSHA1, key, strlen(key));
  CCHmacUpdate(&ctx, data, [message length]);
  CCHmacFinal(&ctx, mac);

  p = hexmac;

  for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
    snprintf(p, 3, "%02x", mac[i]);
    p += 2;
  }

  return [NSString stringWithCString:hexmac encoding:NSASCIIStringEncoding];
}

@end
