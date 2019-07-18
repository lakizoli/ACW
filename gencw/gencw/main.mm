//
//  main.mm
//  gencw
//
//  Created by Laki Zoltán on 2019. 07. 15..
//  Copyright © 2019. Laki Zoltán. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PackageManager.h"

#define GEN_SUCCEEDED	0
#define GEN_FAILED		1

int PrintUsage (const char* msg) {
	printf ("Error: %s\n\n"
			"Usage:\n\n"
			"    gencw <document_path> <database_path>\n\n"
			"Parameters:\n"
			"    document_path: the path of the downloaded Anki packages, like the document dir on the real device.\n"
			"    database_path: the base path of the generated crossword packages, where the folder of the crosswords will be created.\n\n", msg);
	return GEN_FAILED;
}

int main (int argc, const char * argv[]) {
	@autoreleasepool {
		if (argc != 3) {
			return PrintUsage ("Wrong parameters!");
		}
		
		NSURL *docPath = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
		NSURL *dbPath = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[2]]];
		
		PackageManager *man = [PackageManager sharedInstance];
		[man setOverriddenDocumentPath:docPath];
		[man setOverriddenDatabasePath:dbPath];
		
		NSArray<Package*> *packages = [man collectPackages];
		
		//TODO: ...
	}
	
	return GEN_SUCCEEDED;
}
