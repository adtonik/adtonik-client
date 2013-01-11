//
//  ADTLoadAdDelegate.h
//  DemoApp
//
//  Created by Marshall A. Beddoe on 1/10/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ADTLoadAdDelegate <NSObject>

- (void)ADTLoadAdDidReceiveAd:(NSString *)markup;

@end
