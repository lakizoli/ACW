//
//  NetLogger.mm
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 24..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "NetLogger.h"
#import <Flurry.h>
#import <TargetConditionals.h>

@implementation NetLogger

+(void)startSession {
#if TARGET_OS_SIMULATOR
	NSLog (@"Netlogger started");
#else
	NSString* appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

	FlurrySessionBuilder* builder = [[[[[FlurrySessionBuilder new]
										withLogLevel:FlurryLogLevelCriticalOnly]
									   withCrashReporting:YES]
									  withSessionContinueSeconds:10]
									 withAppVersion:appVersionString];
	
	[Flurry startSession:@"9P9572XC7M7B686598VW" withSessionBuilder:builder];
#endif
}

+(void)logEvent:(NSString *)eventName {
#if TARGET_OS_SIMULATOR
	NSLog (@"NetLogger event: %@", eventName);
#else
	[Flurry logEvent:eventName];
#endif
}

+(void)logEvent:(NSString *)eventName withParameters:(NSDictionary<NSString *,NSObject *> *)params {
#if TARGET_OS_SIMULATOR
	NSLog (@"NetLogger event: %@ withParameters: %@", eventName, [params description]);
#else
	[Flurry logEvent:eventName withParameters:params];
#endif
}

@end
