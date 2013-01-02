//
//  ADTLogging.m
//  AdTonik, Inc.
//
//  Created by Marshall Beddoe on 04/27/2012
//  Copyright 2012 AdTonik, Inc. All rights reserved.
//

#import "ADTLogging.h"

static ADTLogLevel ADTLOG_LEVEL = ADTLogLevelInfo;

ADTLogLevel ADTLogGetLevel()
{
	return ADTLOG_LEVEL;
}

void ADTLogSetLevel(ADTLogLevel level)
{
	ADTLOG_LEVEL = level;
}

void _ADTLogTrace(NSString *format, ...)
{
	if (ADTLOG_LEVEL <= ADTLogLevelTrace) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
  }
}

void _ADTLogDebug(NSString *format, ...)
{
	if (ADTLOG_LEVEL <= ADTLogLevelDebug) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
  }
}

void _ADTLogWarn(NSString *format, ...)
{
	if (ADTLOG_LEVEL <= ADTLogLevelWarn) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
  }
}

void _ADTLogInfo(NSString *format, ...)
{
	if (ADTLOG_LEVEL <= ADTLogLevelInfo) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
  }
}

void _ADTLogError(NSString *format, ...)
{
	if (ADTLOG_LEVEL <= ADTLogLevelError) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
  }
}

void _ADTLogFatal(NSString *format, ...)
{
	if (ADTLOG_LEVEL <= ADTLogLevelFatal) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
  }
}