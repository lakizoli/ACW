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
#include "FillTest.hpp"
#include <zip.h>
#include <unzip.h>
#include <vector>
#include <cstdio>

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

static int GenerateCrosswords (NSString* baseName, Package *package, GeneratorInfo *generatorInfo) {
	PackageManager *man = [PackageManager sharedInstance];
	
	//Generate all crossword variation from selected decks
	BOOL generateAllVariations = YES;
	__block int32_t lastPercent = -1;
	
	printf ("Generating crosswords for package: %s\n", [[package name] UTF8String]);
	
	NSString *firstCWName = nil;
	BOOL genRes = YES;
	int32_t cwIndex = 0;
	int32_t cwCount = 0;
	while (genRes) {
		if (generateAllVariations) {
			lastPercent = -1;
			
			//Reload used words
			NSURL *packagePath = [package path];
			[man reloadUsedWords:packagePath info:generatorInfo];
			
			//Add counted name to info
			NSString *countedName = [baseName stringByAppendingString:[NSString stringWithFormat:@" - {%4d}", ++cwIndex]];
			[generatorInfo setCrosswordName:countedName];
			
			printf ("Generating crossword: %s\n", [countedName UTF8String]);
		} else {
			[generatorInfo setCrosswordName:baseName];
		}
		
		if (firstCWName == nil) {
			firstCWName = generatorInfo.crosswordName;
		}
		
		NSString *fileName = [man generateWithInfo:generatorInfo progressCallback:^(float percent, BOOL *stop) {
			int32_t percentVal = (int32_t) (percent * 100.0f + 0.5f);
			if (percentVal != lastPercent) {
				lastPercent = percentVal;
				printf ("Generating: %d%%     \r", percentVal);
			}
		}];
		
		genRes = fileName != nil;		
		if (genRes) {
			++cwCount;
			
			//Test generated crossword's validity
			NSURL *packagePath = [package path];
			if (!FillTest::ValidateCrossword ([[packagePath path] UTF8String], [fileName UTF8String])) { //Generated crossword cannot be filled!
				printf ("\n[FAIL] Package: %s - Generation failed!\n\n", [[package name] UTF8String]);
				return GEN_FAILED;
			}
		}
		
		if (generateAllVariations == NO) {
			break;
		}
	}
	
	[package.state setCrosswordName:firstCWName];
	[package.state setFilledLevel:0];
	[package.state setLevelCount:generateAllVariations ? cwCount : 1];
	[package.state setFilledWordCount:0];
	[package.state setWordCount:[generatorInfo.usedWords count]];
	[man savePackageState:package];
	
	printf ("\nPackage: %s - Generation succeeded!\n\n", [[package name] UTF8String]);
	return GEN_SUCCEEDED;
}

static int UncompressFileToFolder (NSURL* packageURL, NSURL* targetPath, NSString* fileName) {
	unzFile pack = unzOpen ([[packageURL path] UTF8String]);
	if (pack) {
		if (unzLocateFile (pack, [fileName UTF8String], 2) != UNZ_OK) {
			return GEN_FAILED;
		}
		
		unz_file_info info;
		if (unzGetCurrentFileInfo (pack, &info, nullptr, 0, nullptr, 0, nullptr, 0) != UNZ_OK) {
			return GEN_FAILED;
		}
		
		if (unzOpenCurrentFile (pack) != UNZ_OK) {
			return GEN_FAILED;
		}
		
		uint32_t chunkSize = 1024*1024;
		uint32_t chunkCount = (uint32_t) info.uncompressed_size / chunkSize;
		if (info.uncompressed_size % chunkSize > 0) {
			++chunkCount;
		}
		
		NSURL* targetFilePath = [targetPath URLByAppendingPathComponent:fileName];
		std::FILE* dest = std::fopen ([[targetFilePath path] UTF8String], "wb");
		if (dest == nullptr) {
			return GEN_FAILED;
		}
		
		struct AutoCloseDest {
			std::FILE*& dest;
			AutoCloseDest (std::FILE*& dest) : dest (dest) {}
			~AutoCloseDest () { std::fclose (dest); dest = nullptr; }
		} autoCloseDest (dest);
		
		std::vector<uint8_t> buffer (chunkSize);
		for (uint32_t chunk = 0; chunk < chunkCount; ++chunk) {
			uint32_t readCount = chunk == chunkCount - 1 ? (uint32_t) info.uncompressed_size - chunk * chunkSize : chunkSize;
			
			if (unzReadCurrentFile (pack, &buffer[0], readCount) != readCount) {
				return GEN_FAILED;
			}
			
			if (std::fwrite (&buffer[0], sizeof (uint8_t), readCount, dest) != readCount) {
				return GEN_FAILED;
			}
		}
		
		unzCloseCurrentFile (pack);
		unzClose (pack);
	}
	return GEN_SUCCEEDED;
}

static int CompressFolder (NSString *name, NSURL *sourcePath, NSURL *targetPath, NSNumber** packageSize);

static int ShrinkPackage (NSURL* packageURL, NSString* name) {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL* uncompressPath = [packageURL URLByDeletingLastPathComponent];
	uncompressPath = [uncompressPath URLByAppendingPathComponent:[name stringByDeletingPathExtension]];
	if ([fileManager createDirectoryAtURL:uncompressPath
			  withIntermediateDirectories:YES
							   attributes:nil
									error:nil] != YES) {
		return GEN_FAILED;
	}
	
	if (UncompressFileToFolder (packageURL, uncompressPath, @"collection.anki2") != GEN_SUCCEEDED) {
		printf ("Error trimming package.apkg!\n");
		return GEN_FAILED;
	}
	
	if ([fileManager removeItemAtURL:packageURL error:nil] != YES) {
		return GEN_FAILED;
	}
	
	NSNumber *targetSize = nil;
	NSURL* targetPath = [packageURL URLByDeletingLastPathComponent];
	if (CompressFolder (name, uncompressPath, targetPath, &targetSize) != GEN_SUCCEEDED) {
		return GEN_FAILED;
	}
	
	NSURL *compressedPack = [targetPath URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",name]];
	NSURL *apkgPath = [compressedPack URLByDeletingPathExtension];
	if ([fileManager moveItemAtURL:compressedPack toURL:apkgPath error:nil] != YES) {
		return GEN_FAILED;
	}
	
	if ([fileManager removeItemAtURL:uncompressPath error:nil] != YES) {
		return GEN_FAILED;
	}
	
	return GEN_SUCCEEDED;
}

static int CompressFolder (NSString *name, NSURL *sourcePath, NSURL *targetPath, NSNumber** packageSize) {
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
					if ([[name pathExtension] isEqualToString:@"apkg"]) {
						if (ShrinkPackage (fileURL, name) != GEN_SUCCEEDED) {
							printf ("Error shrinking package.apkg!\n");
							return GEN_FAILED;
						}
						
						size = [[fileManager attributesOfItemAtPath:[fileURL path] error:nil] objectForKey:NSFileSize];
					}
					
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
	
	if (packageSize) {
		if ([target getResourceValue:packageSize forKey:NSURLFileSizeKey error:nil] != YES) {
			return GEN_FAILED;
		}
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
		
		struct AutoTime {
			NSDate *start = [NSDate date];
			~AutoTime () {
				NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
				printf ("Generation time: %.3f seconds\n\n", duration);
			}
		} autoTime;
		
		PackageManager *man = [PackageManager sharedInstance];
		[man setOverriddenDocumentPath:docPath];
		[man setOverriddenDatabasePath:dbPath];
		
		NSArray<Package*> *packages = [man collectPackages];
		__block dispatch_group_t dispatchGroup = dispatch_group_create ();
		__block dispatch_queue_t bgQueue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		__block NSMutableDictionary<NSString*, NSNumber*> *packageSizes = [NSMutableDictionary new];
		__block BOOL succeeded = YES;
		__block NSObject *sync = [NSObject new];
		[packages enumerateObjectsUsingBlock:^(Package * _Nonnull package, NSUInteger idx, BOOL * _Nonnull stop) {
			if (!succeeded) { //Stop on error
				*stop = YES;
				return;
			}
			
			dispatch_group_async (dispatchGroup, bgQueue, ^(void) {
				//Configure generation
				NSString *packageFileName = [[package path] lastPathComponent];
				PackageConfig *packageConfig = [cfg getPackageConfig:packageFileName];
				[package.state setOverriddenPackageName:[packageConfig getPackageTitle]];
				NSString *baseName = [packageConfig getBaseName];

				GeneratorInfo *generatorInfo = [man collectGeneratorInfo:[package decks]];
				[generatorInfo setWidth:[packageConfig getWidth]];
				[generatorInfo setHeight:[packageConfig getHeight]];
				[generatorInfo setQuestionFieldIndex:[packageConfig getQuestionIndex]];
				[generatorInfo setSolutionFieldIndex:[packageConfig getSolutionIndex]];
				if ([packageConfig hasSplitArray]) {
					[generatorInfo setSplitArray:[packageConfig getSplitArray]];
				}
				[generatorInfo setSolutionsFixes:[packageConfig getSolutionFixes]];
				
				//Generate crosswords
				if (GenerateCrosswords (baseName, package, generatorInfo) != GEN_SUCCEEDED) {
					@synchronized (sync) {
						if (succeeded) {
							succeeded = NO;
						}
					}
				} else { //Generation succeeded
					//Compress contents of the package and move it to the output
					__block NSNumber *packageSize = nil;
					if (CompressFolder (packageFileName, [package path], [NSURL fileURLWithPath:[cfg getOutputPath]], &packageSize) != GEN_SUCCEEDED) {
						@synchronized (sync) {
							if (succeeded) {
								succeeded = NO;
							}
						}
					} else { //Succeeded compression
						@synchronized (sync) {
							[packageSizes setObject:packageSize forKey:[package name]];
						};
					}
				}
			});
		}];
		
		dispatch_group_wait (dispatchGroup, DISPATCH_TIME_FOREVER);
		
		//Write packs.json besides the packs
		if (succeeded) {
			packages = [packages sortedArrayUsingComparator:^NSComparisonResult(Package*  _Nonnull pack1, Package*  _Nonnull pack2) {
				NSString *name1 = pack1.state.overriddenPackageName;
				if ([name1 length] <= 0) {
					name1 = pack1.name;
				}
				
				NSString *name2 = pack2.state.overriddenPackageName;
				if ([name2 length] <= 0) {
					name2 = pack2.name;
				}
				
				return [name1 compare:name2];
			}];
			
			__block NSMutableArray *json = [NSMutableArray new];
			[packages enumerateObjectsUsingBlock:^(Package * _Nonnull package, NSUInteger idx, BOOL * _Nonnull stop) {
				NSString *packageFileName = [[package path] lastPathComponent];
				PackageConfig *packageConfig = [cfg getPackageConfig:packageFileName];

				NSNumber *packSize = [packageSizes objectForKey:[package name]];
				[json addObject: @{@"name" : [NSString stringWithFormat:@"%@ (%lu words)", package.state.overriddenPackageName, package.state.wordCount],
								   @"fileID" : [packageConfig getGoogleDriveID],
								   @"size" : packSize ? packSize : [NSNumber numberWithUnsignedInteger:0] }];
			}];
			
			NSError *err = nil;
			NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&err];
			if (data == nil || err != nil) { //Failed json conversion
				succeeded = NO;
			} else { //Succeeded json conversion
				NSURL *packDest = [[NSURL fileURLWithPath:[cfg getOutputPath]] URLByAppendingPathComponent:@"packs.json"];
				[data writeToURL:packDest atomically:YES];
			}
		}
		
		return succeeded ? GEN_SUCCEEDED : GEN_FAILED;
	}
}
