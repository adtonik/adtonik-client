//
//  ADTlibacrWrapper.h
//  ADTlibacrWrapper
//
//  Created by Marshall Beddoe on 4/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADTlibacrWrapper : NSObject

+ (NSSet *) getFingerprintsForFile: (NSString *) filename;
+ (NSString *) getACRVersion;

@end
