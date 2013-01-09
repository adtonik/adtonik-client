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

static NSString *kAdTonikSDKVersion = ADT_BUILD_TAG;

#if ADT_USE_DEV_API == 1
  static NSString *kAdTonikHostname = @"http://dev.api.adtonik.net:3000";
#else
  static NSString *kAdTonikHostname = @"http://api.adtonik.net";
#endif
