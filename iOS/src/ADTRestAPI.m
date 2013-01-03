//
//  ADTRestAPI.m
//  ADTDemoApp
//
//  Created by Marshall Beddoe on 4/24/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTRestAPI.h"
#import "ADTAudioACR.h"
#import "ADTRestEnvelope.h"
#import "ADTLogging.h"

@implementation ADTRestAPI

@synthesize timeout = timeout_;
@synthesize appId = appId_;
@synthesize appSecret = appSecret_;
@synthesize udid = udid_;
@synthesize loading = loading_;
@synthesize request = request_;
@synthesize data = data_;
@synthesize headers = headers_;
@synthesize response = response_;
@synthesize delegate = delegate_;
@synthesize refreshTimer = refreshTimer_;
@synthesize state = state_;

#pragma mark -
#pragma mark Initializer Methods

- (id) initWithDelegate: (id<ADTRestAPIDelegate>) delegate andAppId: (NSString *) appId andAppSecret: (NSString *) appSecret andUDID: (NSString *) udid {

  self = [super init];

  if(self) {
    delegate_ = delegate;
    appId_        = [NSString stringWithString:appId];
    appSecret_    = [NSString stringWithString:appSecret];
    udid_         = [udid retain];
    refreshTimer_ = ADT_DEFAULT_REFRESH_TIMER;
    state_        = [[NSDictionary alloc] init];
    request_      = [[NSMutableURLRequest alloc] initWithURL:nil
                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                          timeoutInterval:10.0];
  }

  return self;
}

#pragma mark -
#pragma mark Deallocate

- (void) dealloc {
  [appId_ release];
  [appSecret_ release];
  [request_ release];
  [data_ release];
  [headers_ release];
  [udid_ release];
  [state_ release];

  [super dealloc];
}

#pragma mark -
#pragma mark Fingerprint Query API Method

- (BOOL) queryWithFingerprints: (NSSet *) fingerprints andVersion: (NSString *) acrVersion;
{
  if(loading_) {
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
  request_.URL = [self apiURL:api_path];

  // generate hmac on the data payload..
  NSString *hmac = [ADTRestEnvelope signMessage:requestBody
                                      withAppID:appId_
                                   andAppSecret:appSecret_];

  [request_ setHTTPBody:requestBody];
  [request_ setHTTPMethod:@"POST"];
  [request_ setValue:appId_ forHTTPHeaderField:@"X-ADT-APP-ID"];
  [request_ setValue:hmac forHTTPHeaderField:@"X-ADT-HMAC"];
  [request_ setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [request_ setValue:@"application/json" forHTTPHeaderField:@"Accepts"];

  // Fire off the request
  loading_ = YES;
  conn_ = [NSURLConnection connectionWithRequest:request_ delegate:self];

  ADTLogInfo(@"fired off queryWithFingerprints to %@", request_.URL);

  return YES;
}

#pragma mark -
#pragma mark Cancel Outstanding Request

- (void) cancel {
  [conn_ cancel];
  loading_ = NO;
}

#pragma mark -
#pragma mark NSURLConnectionData Delegate Methods

- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *) response {
  if([response respondsToSelector:@selector(statusCode)]) {
    int statusCode = [((NSHTTPURLResponse *) response) statusCode];

    if(statusCode >= 400) {
      [connection cancel];

      NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:
        [NSString stringWithFormat: NSLocalizedString(@"Server returned status code %d", @""),
         statusCode] forKey:NSLocalizedDescriptionKey];

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
  [data_ appendData:data];
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error {
  ADTLogInfo(@"Request to api server failed to get a valid response. Error: %@", error);

  loading_ = NO;

  // reset refresh timer if there is an error..
  self.refreshTimer = ADT_DEFAULT_REFRESH_TIMER;

  if([delegate_ respondsToSelector:@selector(restAPIError:)])
    [delegate_ restAPIError: error];
}

- (void) connectionDidFinishLoading:(NSURLConnection *) connection {
  loading_ = NO;

  NSError *e = nil;
  NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data_ options:NSJSONReadingMutableContainers error:&e];
  NSNumber *refreshTimerNum = [jsonObject objectForKey:@"refreshTimer"];

  if(!refreshTimerNum)
    self.refreshTimer = ADT_DEFAULT_REFRESH_TIMER;
  else
    self.refreshTimer = [refreshTimerNum integerValue];

  // save the state
  self.state = [jsonObject objectForKey:@"state"];
  
  // check for user opt out flag
  if(e == nil && [[self.state objectForKey:@"optout"] boolValue] == YES) {
    if([delegate_ respondsToSelector:@selector(restAPIOptOut)])
      [delegate_ restAPIOptOut];
    
    return;
  }
    
  // Check for successful response in envelope
  if(e == nil && [ADTRestEnvelope successResponse:jsonObject] == YES) {
    NSDictionary *results = [jsonObject objectForKey:@"data"];

    ADTLogInfo(@"api server returned match %@", results);

    if([delegate_ respondsToSelector:@selector(restAPIResponse:successfully:)])
      [delegate_ restAPIResponse: results successfully: YES];

  } else {

    if(e) {
      ADTLogError(@"experienced error decoding json response: %@", e);
    }

    ADTLogInfo(@"api server returned no successful match");

    if([delegate_ respondsToSelector:@selector(restAPIResponse:successfully:)])
      [delegate_ restAPIResponse: nil successfully: NO];
  }
}

#pragma mark -
#pragma mark URL Construction

- (NSURL *) apiURL: (NSString *) URL {

  NSString *escapedUri = [URL stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

  NSURL *fullUri = [NSURL URLWithString:escapedUri
                          relativeToURL:[NSURL URLWithString:ADT_HOSTNAME]];

  ADTLogInfo(@"uri path equal to %@", [fullUri absoluteString]);

  return fullUri;
}

@end
