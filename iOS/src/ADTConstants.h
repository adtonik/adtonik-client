//
//  ADTConstants.h
//  DemoApp
//
//  Created by Marshall Beddoe on 4/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTVersion.h"

#define ADT_USE_DEV_API 0

#define ADT_SAMPLE_SECONDS 6
#define ADT_DEFAULT_REFRESH_TIMER 10

static NSString *ADT_SDK_VERSION = @"1.0.0";

#if ADT_USE_DEV_API == 1
  static NSString *ADT_HOSTNAME = @"http://dev.api.adtonik.net:3000";
#else
  static NSString *ADT_HOSTNAME = @"http://api.adtonik.net";
#endif