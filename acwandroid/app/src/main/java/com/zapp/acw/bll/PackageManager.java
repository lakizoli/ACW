package com.zapp.acw.bll;

import android.util.Log;

import com.zapp.acw.FileUtils;

import java.io.File;

public final class PackageManager {
	private String _overriddenDocURL = null;
	private String _overriddenDatabaseURL = null;

	//region Singleton construction
	private static PackageManager inst = new PackageManager ();

	private PackageManager () {
	}

	public static PackageManager sharedInstance () {
		return inst;
	}
	//endregion

	//region Collecting packages
	public void setOverriddenDocumentPath (String url) {
		_overriddenDocURL = url;
	}

	public void setOverriddenDatabasePath (String url) {
		_overriddenDatabaseURL = url;
	}

	public void unzipDownloadedPackage (String downloadedPackagePath, String packageName) {
		//Check destination (if already exists we have to delete it!)
		String packagesPath = databasePath ();
		String destPath = FileUtils.pathByAppendingPathComponent (packagesPath, packageName);

		if (new File (destPath).exists ()) {
			if (!FileUtils.deleteRecursive (destPath)) {
				Log.e ("PackageManager", "Cannot unzip package, because its already exist, and cannot be removed!");
				return;
			}
		}

//		//Create the new dir
//		if (![self ensureDirExists:destPath]) {
//			return;
//		}
//
//		//Unzip package's content
//		unzFile pack = unzOpen ([[downloadedPackagePath path] UTF8String]);
//		if (pack == nullptr) {
//			NSLog (@"Cannot open package to unzip!");
//			return;
//		}
//
//		BOOL first = YES;
//		while (true) {
//			//Locate the next file
//			int32_t nextFileRes = first ? unzGoToFirstFile (pack) : unzGoToNextFile (pack);
//			if (nextFileRes != UNZ_OK && nextFileRes != UNZ_END_OF_LIST_OF_FILE) {
//				NSLog (@"Cannot locate file in package to unzip!");
//				return;
//			}
//			first = NO;
//
//			//Read file info
//			unz_file_info fileInfo;
//			char fileNameBuffer[512];
//			if (unzGetCurrentFileInfo (pack, &fileInfo, fileNameBuffer, 512, nullptr, 0, nullptr, 0) != UNZ_OK) {
//				NSLog (@"Cannot read file info in package to unzip!");
//				return;
//			}
//
//			if (fileInfo.size_filename >= 512) {
//				NSLog (@"Filename too long in package to unzip!");
//				return;
//			}
//
//			std::string fileName (&fileNameBuffer[0], &fileNameBuffer[fileInfo.size_filename]);
//
//			//Unpack file to the destination
//			if (unzOpenCurrentFile (pack) != UNZ_OK) {
//				NSLog (@"Cannot open file in package to unzip!");
//				return;
//			}
//
//			NSURL *destFilePath = [destPath URLByAppendingPathComponent:[NSString stringWithUTF8String:fileName.c_str ()]];
//			FILE *destFile = fopen ([[destFilePath path] UTF8String], "wb");
//			if (destFile == nullptr) {
//				NSLog (@"Cannot create file at destination!");
//				return;
//			}
//
//			int32_t chunkLen = 1024*1024;
//			std::vector<uint8_t> buffer (chunkLen);
//			int32_t readLen = 0;
//			while ((readLen = unzReadCurrentFile (pack, &buffer[0], chunkLen)) != 0) {
//				if (fwrite (&buffer[0], 1, readLen, destFile) != readLen) {
//					NSLog (@"Cannot write file at destination!");
//					return;
//				}
//			}
//
//			fclose (destFile);
//
//			if (unzCloseCurrentFile (pack) != UNZ_OK) {
//				NSLog (@"Cannot close file in package to unzip!");
//				return;
//			}
//
//			//Check last file
//			if (nextFileRes == UNZ_END_OF_LIST_OF_FILE) { //If we reached the last file in the last cycle, then break
//				break;
//			}
//		}
//
//		unzClose (pack);
	}

	private boolean ensureDirExists (String dir) {
//		NSFileManager *fileManager = [NSFileManager defaultManager];
//
//		BOOL isDir = NO;
//		BOOL exists = [fileManager fileExistsAtPath:[dir path] isDirectory:&isDir] == YES;
//
//		BOOL createDir = NO;
//		if (!exists) { //We have nothing at destination, so let's create a dir...
//			createDir = YES;
//		} else if (!isDir) { //We have some file at place, so we have to delete it before creating the dir...
//			NSError *err = nil;
//			if ([fileManager removeItemAtPath:[dir path] error:&err] != YES) {
//				NSLog (@"Cannot remove file at path: %@, err: %@", [dir path], err);
//				return NO;
//			}
//			createDir = YES;
//		}
//
//		if (createDir) {
//			NSError *err = nil;
//			if ([fileManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&err] != YES) {
//				NSLog (@"Cannot create database at url: %@, err: %@", dir, err);
//				return NO;
//			}
//		}
//
		return true;
	}

	private String documentPath () {
		if (_overriddenDocURL != null) {
			return _overriddenDocURL;
		}

		//TODO: find out the document dir of Android!!!
//		return [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		return null;
	}

	private String databasePath () {
		String dbDir = null;
		if (_overriddenDatabaseURL != null) {
			dbDir = _overriddenDatabaseURL;
		} else {
			//TODO: find out the document dir of Android!!!
			String docDir = null; //[[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
			dbDir = FileUtils.pathByAppendingPathComponent (docDir, "packages");
		}

		if (!ensureDirExists (dbDir)) {
			return null;
		}

		return dbDir;
	}

//-(NSArray<Package*>*)collectPackages;
//-(void)savePackageState:(Package*)pack;
	//endregion



//-(NSDictionary<NSString*, NSArray<SavedCrossword*>*>*)collectSavedCrosswords;
//-(GeneratorInfo*)collectGeneratorInfo:(NSArray<Deck*>*)decks;
//-(void)reloadUsedWords:(NSURL*)packagePath info:(GeneratorInfo*)info;
//
//-(NSString*)trimQuestionField:(NSString*)questionField;
//-(NSString*)trimSolutionField:(NSString*)solutionField splitArr:(NSArray<NSString*>*)splitArr solutionFixes:(NSDictionary<NSString*, NSString*>*)solutionFixes;
//-(BOOL)generateWithInfo:(GeneratorInfo*)info progressCallback:(void(^)(float, BOOL*))progressCallback;

}
