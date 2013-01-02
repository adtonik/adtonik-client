//
//  ADTLogging.h
//  DemoApp
//
//  Created by Marshall Beddoe on 4/27/12.
//  Copyright (c) 2012 AdTonik, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ADTConstants.h"

typedef enum
{
	ADTLogLevelAll		= 1 << 0,
	ADTLogLevelTrace	= 1 << 1,
	ADTLogLevelDebug	= 1 << 2,
	ADTLogLevelInfo		= 1 << 3,
	ADTLogLevelWarn		= 1 << 4,
	ADTLogLevelError	= 1 << 5,
	ADTLogLevelFatal	= 1 << 6,
	ADTLogLevelOff		= 1 << 7
} ADTLogLevel;

ADTLogLevel ADTLogGetLevel(void);

void ADTLogSetLevel(ADTLogLevel level);

void _ADTLogTrace(NSString *format, ...);
void _ADTLogDebug(NSString *format, ...);
void _ADTLogInfo(NSString *format, ...);
void _ADTLogWarn(NSString *format, ...);
void _ADTLogError(NSString *format, ...);
void _ADTLogFatal(NSString *format, ...);

#if DEBUG

#define ADTLogTrace(s, ...) _ADTLogTrace(@"<ADTONIK %@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define ADTLogDebug(s, ...) _ADTLogDebug(@"<ADTONIK %@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define ADTLogInfo(s, ...)  _ADTLogInfo(@"<ADTONIK %@:(%d)> %@",  [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define ADTLogTrace(s, ...) _ADTLogTrace(@"<ADTONIK %@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define ADTLogWarn(s, ...)  _ADTLogWarn( @"<ADTONIK %@:(%d)> %@",  [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define ADTLogError(s, ...) _ADTLogError(@"<ADTONIK %@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define ADTLogFatal(s, ...) _ADTLogFatal(@"<ADTONIK %@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])

#else

#define ADTLogTrace(...) {}
#define ADTLogDebug(...) {}
#define ADTLogInfo(...)  {}
#define ADTLogWarn(...)  {}
#define ADTLogError(...) {}
#define ADTLogFatal(...) {}

#endif
