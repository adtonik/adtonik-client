//
//  ADTAudioACR.h
//  ADTlibacrWrapper
//
//  Created by Marshall A. Beddoe on 1/25/13.
//  Copyright (c) 2013 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^acrCallback)(NSSet *, NSString *);

@interface ADTAudioACR : NSOperation

- (id) initWithFilename: (NSString *) filename andCallback:(acrCallback) block;

+ (void) computeSignatures: (NSString *) filename callback:(acrCallback) block;

+ (NSString *) getACRVersion;

@end
