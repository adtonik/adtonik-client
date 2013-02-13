//
//  ADTLoadAd.m
//  DemoApp
//
//  Created by Marshall A. Beddoe on 1/10/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import "ADTLoadAd.h"

@interface ADTLoadAd () <NSURLConnectionDataDelegate>

@property (nonatomic, copy)   NSString* udid;
@property (nonatomic, weak)   id delegate;
@property (nonatomic, strong) NSURLConnection* conn;
@property (nonatomic, strong) NSURLRequest* request;
@property (nonatomic, strong) NSMutableData* data;

@end

@implementation ADTLoadAd

- (id)initWithDelegate:(id<ADTLoadAdDelegate>)delegate andUDID:(NSString *)udid
{
  self = [super init];
  
  if(self) {
    _udid = udid;
    _delegate = delegate;
    
    NSString *adServerURL = [NSString stringWithFormat:@"http://api.adtonik.net/demo/%@", udid];

    NSURL *url = [NSURL URLWithString:adServerURL];
    
    _request = [[NSURLRequest alloc] initWithURL:url
                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                 timeoutInterval:10.0];
  }
  
  return self;
}

- (void)loadAd
{
  self.loading = YES;
  self.conn = [NSURLConnection connectionWithRequest:self.request delegate:self];
}

#pragma mark -
#pragma mark NSURLConnectionData Delegate Methods

- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *)response
{
  if([response respondsToSelector:@selector(statusCode)]) {
    int statusCode = [((NSHTTPURLResponse *) response) statusCode];
    
    if(statusCode >= 400) {
      [connection cancel];
      
      NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Server returned status code %d", @""),
                                  statusCode]};
      
      NSError *statusError = [NSError errorWithDomain:@"adtonik.net"
                                                 code:statusCode
                                             userInfo:errorInfo];
      
      [self connection:connection didFailWithError:statusError];
      
      return;
    }
  }
  
  // Initialize data
  self.data = [NSMutableData data];
}

- (void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data
{
  [self.data appendData:data];
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error
{
  self.loading = NO;
  
  NSLog(@"request failed %@", error);
}

- (void) connectionDidFinishLoading:(NSURLConnection *) connection
{
  self.loading = NO;
  
  NSString *response = [NSString stringWithCString:[self.data bytes] encoding:NSUTF8StringEncoding];
  
  if(response && response.length > 0) {
    if([self.delegate respondsToSelector:@selector(ADTLoadAdDidReceiveAd:)])
      [self.delegate ADTLoadAdDidReceiveAd:response];
  }
}

@end
