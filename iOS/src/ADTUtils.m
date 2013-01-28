//
//  ADTUtils.m
//  DemoApp
//
//  Created by Marshall A. Beddoe on 1/25/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import "ADTUtils.h"
#import <CommonCrypto/CommonDigest.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= ADT_IOS_6_06000
#import <AdSupport/AdSupport.h>
#endif

#pragma mark -
#pragma mark Compute SHA1 Hash

NSString *ADTSHA1Digest(NSString *string)
{
  unsigned char digest[CC_SHA1_DIGEST_LENGTH];
  NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
  CC_SHA1([data bytes], [data length], digest);
  
  NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
    [output appendFormat:@"%02x", digest[i]];
  }
  
  return output;
}

#pragma mark -
#pragma mark Lookup Device Advertising Identifier

NSString *ADTAdvertisingIdentifier(void)
{
  NSString *identifier = nil;
  
  if (NSClassFromString(@"ASIdentifierManager")) {
    identifier = ADTSHA1Digest([[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString]);
  } else {
#if __IPHONE_OS_VERSION_MAX_ALLOWED < ADT_IOS_6_0
    identifier = ADTSHA1Digest([[UIDevice currentDevice] uniqueIdentifier]);
#endif
  }

  return identifier;
}
