//
//  ADTRestAPI.m
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/24/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTRestAPI.h"
#import "ADTClient.h"
#import "ADTRestEnvelope.h"
#import "ADTLogging.h"

@interface ADTRestAPI () <NSURLConnectionDataDelegate>


@property (nonatomic, copy) NSString* appId;
@property (nonatomic, copy) NSString* appSecret;
@property (nonatomic, copy) NSString* udid;
@property (nonatomic, copy) NSDictionary* response;
@property (nonatomic, copy) NSDictionary* state;

@property (nonatomic, assign) NSUInteger timeout;
@property (nonatomic, assign) id <ADTRestAPIDelegate> delegate;

@property (nonatomic, retain) NSURLConnection* conn;
@property (nonatomic, retain) NSMutableURLRequest* request;
@property (nonatomic, retain) NSMutableData* data;
@property (nonatomic, retain) NSDictionary* headers;

@end

@implementation ADTRestAPI

#pragma mark -
#pragma mark Initializer Methods

- (id) initWithDelegate:(id<ADTRestAPIDelegate>) delegate
               andAppId:(NSString *) appId
           andAppSecret:(NSString *) appSecret
                andUDID:(NSString *) udid
{
  self = [super init];

  if(self) {
    _delegate     = delegate;
    _appId        = [NSString stringWithString:appId];
    _appSecret    = [NSString stringWithString:appSecret];
    _udid         = [udid retain];
    _refreshTimer = ADT_DEFAULT_REFRESH_TIMER;
    _state        = [[NSDictionary alloc] init];
    _request      = [[NSMutableURLRequest alloc] initWithURL:nil
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:10.0];
  }

  return self;
}

#pragma mark -
#pragma mark Deallocate

- (void) dealloc
{
  [_appId release];
  [_appSecret release];
  [_request release];
  [_data release];
  [_headers release];
  [_udid release];
  [_state release];

  [super dealloc];
}

#pragma mark -
#pragma mark Fingerprint Query API Method

- (BOOL) queryWithFingerprints:(NSSet *)fingerprints andVersion:(NSString *)acrVersion
{
  if(self.isLoading) {
    ADTLogInfo(@"queryWithFingerprints is already loading a request");
    return NO;
  }
  
  NSData *requestBody = [ADTRestEnvelope messageWithData:[fingerprints allObjects]
                                                   state:self.state
                                                   appId:self.appId
                                               appSecret:self.appSecret
                                              acrVersion:acrVersion
                                                 andUDID:self.udid];

  NSString *api_path = [NSString stringWithFormat:@"/api/v1/acr/%@/%@", self.appId, self.udid];

  // Setup the request object
  self.request.URL = [self apiURL:api_path];

  // Generate HMAC on the data payload
  NSString *hmac = [ADTRestEnvelope signMessage:requestBody
                                      withAppID:self.appId
                                   andAppSecret:self.appSecret];

  [self.request setHTTPBody:requestBody];
  [self.request setHTTPMethod:@"POST"];
  [self.request setValue:self.appId forHTTPHeaderField:@"X-ADT-APP-ID"];
  [self.request setValue:hmac forHTTPHeaderField:@"X-ADT-HMAC"];
  [self.request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [self.request setValue:@"application/json" forHTTPHeaderField:@"Accepts"];

  // Fire off the request
  self.loading = YES;
  self.conn = [NSURLConnection connectionWithRequest:self.request delegate:self];

  ADTLogInfo(@"fired off queryWithFingerprints to %@", self.request.URL);

  return YES;
}

#pragma mark -
#pragma mark Cancel Outstanding Request

- (void) cancel
{
  [self.conn cancel];
  self.loading = NO;
}

#pragma mark -
#pragma mark NSURLConnectionData Delegate Methods

- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *)response {
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

  ADTLogInfo(@"ADTRestAPI (%p) received response from API server", self);

  // Initialize data
  NSMutableData *newData = [NSMutableData data];
  self.data = newData;

  // Parse response headers
  NSDictionary *headers = [(NSHTTPURLResponse *) response allHeaderFields];

  self.headers = headers;
}

- (void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data {
  [self.data appendData:data];
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error {
  ADTLogInfo(@"Request to api server failed to get a valid response. Error: %@", error);

  self.loading = NO;

  // reset refresh timer if there is an error..
  self.refreshTimer = ADT_DEFAULT_REFRESH_TIMER;

  if([self.delegate respondsToSelector:@selector(restAPIDidErrorOccur:)])
    [self.delegate restAPIDidErrorOccur:error];
}

- (void) connectionDidFinishLoading:(NSURLConnection *) connection {
  self.loading = NO;

  NSError *error = nil;
  
  NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:self.data
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
  
  NSNumber *refreshTimerNum = jsonObject[@"refreshTimer"];

  if(!refreshTimerNum) {
    self.refreshTimer = ADT_DEFAULT_REFRESH_TIMER;
  } else {
    self.refreshTimer = [refreshTimerNum integerValue];
  }

  // Save the state
  self.state = jsonObject[@"state"];
  
  // Check for user opt out flag
  if(error == nil && [self.state[@"optout"] boolValue] == YES) {
    if([self.delegate respondsToSelector:@selector(restAPIDidReceiveOptOut)])
      [self.delegate restAPIDidReceiveOptOut];
    
    return;
  }
  
  BOOL success;
  
  if(error) {
    success = NO;
    ADTLogError(@"experienced error decoding json response: %@", error);
  } else {
    success = [ADTRestEnvelope successResponse:jsonObject];
  }
  
  ADTLogInfo(@"Received %@ response from server", success == 1 ? @"success" : @"error");
  
  if([self.delegate respondsToSelector:@selector(restAPIDidReceiveResponse:successfully:)])
    [self.delegate restAPIDidReceiveResponse:jsonObject successfully:success];
  
  return;
}

#pragma mark -
#pragma mark URL Construction

- (NSURL *) apiURL:(NSString *) URL {

  NSString *escapedUri = [URL stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

  NSURL *fullUri = [NSURL URLWithString:escapedUri
                          relativeToURL:[NSURL URLWithString:kADTHostname]];

  ADTLogInfo(@"URI path equal to %@", [fullUri absoluteString]);

  return fullUri;
}

@end
