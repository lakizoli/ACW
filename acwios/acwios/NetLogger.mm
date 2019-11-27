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
	
	[Flurry setUserID:[self getUserID]];
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

+(void)logPaymentTransaction:(SKPaymentTransaction*)transaction {
#if TARGET_OS_SIMULATOR
	NSLog (@"NetLogger logPaymentTransaction: %@", [transaction description]);
#else
	[Flurry logPaymentTransaction:transaction statusCallback:^(FlurryTransactionRecordStatus status) {
	
	}];
#endif
}

+ (BOOL) ensureDirExists:(NSURL*)dir {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	BOOL isDir = NO;
	BOOL exists = [fileManager fileExistsAtPath:[dir path] isDirectory:&isDir] == YES;
	
	BOOL createDir = NO;
	if (!exists) { //We have nothing at destination, so let's create a dir...
		createDir = YES;
	} else if (!isDir) { //We have some file at place, so we have to delete it before creating the dir...
		NSError *err = nil;
		if ([fileManager removeItemAtPath:[dir path] error:&err] != YES) {
			NSLog (@"Cannot remove file at path: %@, err: %@", [dir path], err);
			return NO;
		}
		createDir = YES;
	}
	
	if (createDir) {
		NSError *err = nil;
		if ([fileManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&err] != YES) {
			NSLog (@"Cannot create database at url: %@, err: %@", dir, err);
			return NO;
		}
	}
	
	return YES;
}

+ (NSURL*) userIDPath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *appSupportDir = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	if (![self ensureDirExists:appSupportDir]) {
		return nil;
	}
	
	NSURL *userIDPath = [appSupportDir URLByAppendingPathComponent:@"flurry.dat" isDirectory:NO];
	return userIDPath;
}

+(NSString*)getUserID {
	NSURL *userIDPath = [self userIDPath];
	if (userIDPath == nil) {
		return nil;
	}
	
	NSString *userID = [NSString stringWithContentsOfURL:userIDPath encoding:NSUTF8StringEncoding error:nil];
	if (userID == nil) {
		userID = [[NSUUID UUID] UUIDString];
		[userID writeToURL:userIDPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
	
	return userID;
}

@end
