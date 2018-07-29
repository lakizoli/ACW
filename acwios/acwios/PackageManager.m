//
//  PackageManager.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "PackageManager.h"

@implementation PackageManager

-(id)init {
	self = [super init];
	if (self) {
		//...
	}
	return self;
}

+(PackageManager*) sharedInstance {
	static PackageManager *instance = nil;
	if (instance == nil) {
		instance = [[PackageManager alloc] init];
	}
	return instance;
}

- (NSURL*) documentPath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL*) databasePath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *docDir = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	NSURL *dbDir = [docDir URLByAppendingPathComponent:@"packages" isDirectory:YES];
	
	BOOL isDir = NO;
	BOOL exists = [fileManager fileExistsAtPath:[dbDir path] isDirectory:&isDir] == YES;
	
	BOOL createDir = NO;
	if (!exists) { //We have nothing at destination, so let's create a dir...
		createDir = YES;
	} else if (!isDir) { //We have some file at place, so we have to delete it before creating the dir...
		NSError *err = nil;
		if ([fileManager removeItemAtPath:[dbDir path] error:&err] != YES) {
			NSLog (@"Cannot remove file at path: %@, err: %@", [dbDir path], err);
			return nil;
		}
		createDir = YES;
	}
	
	if (createDir) {
		NSError *err = nil;
		if ([fileManager createDirectoryAtURL:dbDir withIntermediateDirectories:YES attributes:nil error:&err] != YES) {
			NSLog (@"Cannot create database at url: %@, err: %@", dbDir, err);
			return nil;
		}
	}

	return dbDir;
}

-(NSArray<Package*>*) collectPackages {
	NSURL *docDir = [self documentPath];
	NSURL *dbDir = [self databasePath];
	
	//Move packages from document dir to database
	//...
	
	//Enumerate packages in database
	//...
	
	//Extract package's level1 informations
	//...
	
	return nil;
}

@end
