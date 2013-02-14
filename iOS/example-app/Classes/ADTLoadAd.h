//
//  ADTLoadAd.h
//  DemoApp
//
//  Created by Marshall A. Beddoe on 1/10/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ADTLoadAdDelegate.h"

@interface ADTLoadAd : NSObject

@property (getter=isLoading) BOOL loading;

- (id)initWithDelegate:(id<ADTLoadAdDelegate>) delegate andUDID:(NSString *)udid;

- (void)loadAd;


@end
