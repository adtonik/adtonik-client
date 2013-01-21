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

static NSString *kADTSDKVersion = ADT_BUILD_TAG;

#if ADT_USE_DEV_API == 1
  static NSString *kADTHostname = @"http://dev.api.adtonik.net:3000";
#else
  static NSString *kADTHostname = @"http://api.adtonik.net";
#endif

// Error domain
static NSString *const kADTClientErrorDomain = @"com.adtonik.adtclient";

// Error codes
static NSInteger const kADTError = 1;
static NSInteger const kADTAudioError = 2;
static NSInteger const kADTAudioNoFingerprints = 3;
static NSInteger const kADTAPIError = 4;
