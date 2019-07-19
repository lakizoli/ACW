//
//  main.mm
//  gencw
//
//  Created by Laki Zoltán on 2019. 07. 15..
//  Copyright © 2019. Laki Zoltán. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PackageManager.h"
#import "Config.h"
#include <zip.h>
#include <vector>

#define GEN_SUCCEEDED	0
#define GEN_FAILED		1

static int PrintUsage (const char* msg) {
	printf ("Error: %s\n\n"
			"Usage:\n\n"
			"    gencw <document_path> <database_path> <config_path>\n\n"
			"Parameters:\n"
			"    document_path: the path of the downloaded Anki packages, like the document dir on the real device.\n"
			"    database_path: the base path of the generated crossword packages, where the folder of the crosswords will be created.\n"
			"    config_path: the path of the configuration json.\n\n", msg);
	return GEN_FAILED;
}

static void GenerateCrosswords (NSString* baseName, Package *package, GeneratorInfo *generatorInfo) {
	PackageManager *man = [PackageManager sharedInstance];
	
	//Generate all crossword variation from selected decks
	BOOL generateAllVariations = YES;
	__block int32_t lastPercent = -1;
	
	printf ("Generating crosswords for package: %s\n", [[package name] UTF8String]);
	
	BOOL genRes = YES;
	int32_t cwIndex = 0;
	while (genRes) {
		if (generateAllVariations) {
			lastPercent = -1;
			
			//Reload used words
			NSURL *packagePath = [package path];
			[man reloadUsedWords:packagePath info:generatorInfo];
			
			//Add counted name to info
			NSString *countedName = [baseName stringByAppendingString:[NSString stringWithFormat:@" - {%d}", ++cwIndex]];
			[generatorInfo setCrosswordName:countedName];
			
			printf ("Generating crossword: %s\n", [countedName UTF8String]);
		} else {
			[generatorInfo setCrosswordName:baseName];
		}
		
		genRes = [man generateWithInfo:generatorInfo progressCallback:^(float percent, BOOL *stop) {
			int32_t percentVal = (int32_t) (percent * 100.0f + 0.5f);
			if (percentVal != lastPercent) {
				lastPercent = percentVal;
				printf ("Generating: %d%%     \r", percentVal);
			}
		}];
		
		if (generateAllVariations == NO) {
			break;
		}
	}
	
	printf ("\nPackage: %s - Generation succeeded!\n\n", [[package name] UTF8String]);
}

static int CompressFolder (NSString *name, NSURL *sourcePath, NSURL *targetPath) {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants |
		NSDirectoryEnumerationSkipsPackageDescendants |
		NSDirectoryEnumerationSkipsHiddenFiles;
	NSDirectoryEnumerator<NSURL*> *enumerator = [fileManager enumeratorAtURL:sourcePath
												  includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLNameKey, NSURLCreationDateKey, NSURLFileSizeKey]
																	 options:options
																errorHandler:nil];
	
	NSURL *target = [targetPath URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",name]];
	zipFile pack = zipOpen ([[target path] UTF8String], false);
	if (pack) {
		for (NSURL *fileURL in enumerator) {
			NSNumber *isFile = nil;
			if ([fileURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil] == YES && [isFile boolValue]) {
				NSString *name = nil;
				NSDate *date = nil;
				NSNumber *size = nil;
				if ([fileURL getResourceValue:&name forKey:NSURLNameKey error:nil] == YES &&
					[fileURL getResourceValue:&date forKey:NSURLCreationDateKey error:nil] == YES &&
					[fileURL getResourceValue:&size forKey:NSURLFileSizeKey error:nil] == YES)
				{
					zip_fileinfo zi;
					memset (&zi, 0, sizeof (zi));
				
					NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
						| NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
					NSDateComponents *components = [[NSCalendar currentCalendar] components:units fromDate:date];
					zi.tmz_date.tm_sec = (uint32_t) [components second];
					zi.tmz_date.tm_min = (uint32_t) [components minute];
					zi.tmz_date.tm_hour = (uint32_t) [components hour];
					zi.tmz_date.tm_mday = (uint32_t) [components day];
					zi.tmz_date.tm_mon = (uint32_t) [components month];
					zi.tmz_date.tm_year = (uint32_t) [components year];
					
					FILE *inFile = fopen ([[fileURL path] UTF8String], "rb");
					if (!inFile) {
						printf ("Error opening source file for read!\n");
						return GEN_FAILED;
					}

					if (zipOpenNewFileInZip (pack, [name UTF8String], &zi, NULL, 0, NULL, 0, NULL, Z_DEFLATED, Z_DEFAULT_COMPRESSION) != ZIP_OK) {
						printf ("Error opening target file for write in zip!\n");
						return GEN_FAILED;
					}

					uint64_t chunkSize = 1024*1024;
					uint64_t chunkCount = [size unsignedLongLongValue] / chunkSize;
					if ([size unsignedLongLongValue] % chunkSize > 0) {
						++chunkCount;
					}
					
					std::vector<uint8_t> buffer (chunkSize);
					for (uint64_t chunk = 0; chunk < chunkCount; ++chunk) {
						uint32_t readCount = chunk == chunkCount - 1 ? uint32_t ([size unsignedLongLongValue] % chunkSize) : uint32_t (chunkSize);
						if (fread (&buffer[0], sizeof (uint8_t), readCount, inFile) != readCount) {
							printf ("Error reading file in zip!\n");
							return GEN_FAILED;
						}

						if (zipWriteInFileInZip (pack, &buffer[0], readCount) != ZIP_OK) {
							printf ("Error writing file in zip!\n");
							return GEN_FAILED;
						}
					}
					
					zipCloseFileInZip (pack);
				}
			}
		}
		
		zipClose (pack, NULL);
	}
	
	return GEN_SUCCEEDED;
}

int main (int argc, const char * argv[]) {
	@autoreleasepool {
		if (argc != 4) {
			return PrintUsage ("Wrong parameters!");
		}
		
		NSURL *docPath = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
		NSURL *dbPath = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[2]]];
		NSURL *cfgPath = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[3]]];
		
		Config *cfg = [Config createWithURL:cfgPath];
		if (cfg == nil) {
			printf ("Cannot read configuration at path: %s\n\n", [[cfgPath path] UTF8String]);
			return GEN_FAILED;
		}
		
		PackageManager *man = [PackageManager sharedInstance];
		[man setOverriddenDocumentPath:docPath];
		[man setOverriddenDatabasePath:dbPath];
		
		NSArray<Package*> *packages = [man collectPackages];
		__block BOOL succeeded = YES;
		[packages enumerateObjectsUsingBlock:^(Package * _Nonnull package, NSUInteger idx, BOOL * _Nonnull stop) {
			//Configure generation
			NSString *packageFileName = [[package path] lastPathComponent];
			PackageConfig *packageConfig = [cfg getPackageConfig:packageFileName];
			NSString *baseName = [packageConfig getBaseName];

			GeneratorInfo *generatorInfo = [man collectGeneratorInfo:[package decks]];
			[generatorInfo setWidth:[packageConfig getWidth]];
			[generatorInfo setHeight:[packageConfig getHeight]];
			[generatorInfo setQuestionFieldIndex:[packageConfig getQuestionIndex]];
			[generatorInfo setSolutionFieldIndex:[packageConfig getSolutionIndex]];
			
			//Generate crosswords
			GenerateCrosswords (baseName, package, generatorInfo);
			
			//Compress contents of the package and move it to the output
			if (CompressFolder (packageFileName, [package path], [NSURL fileURLWithPath:[cfg getOutputPath]]) != GEN_SUCCEEDED) {
				succeeded = NO;
				*stop = YES;
			}
		}];
		
		return succeeded ? GEN_SUCCEEDED : GEN_FAILED;
	}
}
