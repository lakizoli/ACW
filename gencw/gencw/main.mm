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
			NSString *countedName = [baseName stringByAppendingString:[NSString stringWithFormat:@" - {%4d}", ++cwIndex]];
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

static int CompressFolder (NSString *name, NSURL *sourcePath, NSURL *targetPath);

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
	
	NSURL* targetPath = [packageURL URLByDeletingLastPathComponent];
	if (CompressFolder (name, uncompressPath, targetPath) != GEN_SUCCEEDED) {
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
