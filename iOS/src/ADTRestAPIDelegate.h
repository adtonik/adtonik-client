//
//  ADTRestAPIDelegate.h
//  DemoApp
//
//  Created by Marshall Beddoe on 4/30/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ADTRestAPIDelegate <NSObject>

- (void) restAPIResponse:(NSDictionary *) results successfully:(BOOL) flag;
- (void) restAPIError:(id) error;

- (void) restAPIOptOut;

@end