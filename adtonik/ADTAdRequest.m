//
//  ADTAdRequest.m
//  DemoApp
//
//  Created by Marshall A. Beddoe on 2/15/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import "ADTAdView.h"
#import "ADTAdRequest.h"
#import "ADTUtils.h"

@interface ADTAdRequest () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection*  conn;
@property (nonatomic, strong) NSURLRequest*     urlRequest;
@property (nonatomic, strong) NSMutableData*    data;

@end

@implementation ADTAdRequest

#pragma mark -
#pragma mark Initialize Object

+ (ADTAdRequest *) request
{
  return [[ADTAdRequest alloc] init];
}

#pragma mark -
#pragma mark Request Ad Tag

- (void)requestAd:(CGSize)size appID:(NSString *)appID
{
  if(self.isLoading)
    return;
  
  // TODO: Collect location information if available

  NSString *requestURL = [NSString stringWithFormat:@"http://ads.adtonik.net/ads/%@/%@/?w=%d&h=%d",
                          appID, ADTAdvertisingIdentifier(), (int)size.width, (int)size.height];
  
  NSURL *URL = [NSURL URLWithString:requestURL];
  
  self.urlRequest = [[NSURLRequest alloc] initWithURL:URL
                                          cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                      timeoutInterval:10.0];
  
  self.loading = YES;
  self.conn = [NSURLConnection connectionWithRequest:self.urlRequest delegate:self];
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  if([response respondsToSelector:@selector(statusCode)]) {
    int statusCode = [((NSHTTPURLResponse *) response) statusCode];
    
    if(statusCode != 200) {
      [connection cancel];
      
      NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:
                                    [NSString stringWithFormat:NSLocalizedString(@"Server returned status code %d", @""),
                                     statusCode]};
      
      NSError *statusError = [NSError errorWithDomain:@"adtonik.net"
                                                 code:statusCode
                                             userInfo:errorInfo];
      
      [self connection:connection didFailWithError:statusError];
      
      return;
    }
  }
  
  self.data = [NSMutableData data];
}

- (void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data
{
  [self.data appendData:data];
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error
{
  self.loading = NO;
  
  if([self.delegate respondsToSelector:@selector(didFailWithError:)])
    [self.delegate didFailWithError:error];
}

- (void) connectionDidFinishLoading:(NSURLConnection *) connection
{
  self.loading = NO;
    
  if([self.delegate respondsToSelector:@selector(didReceiveAdResponse:)])
    [self.delegate didReceiveAdResponse:self.data];
}

@end
