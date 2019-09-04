//
// Created by Laki Zoltán on 2019-09-04.
//

#include <set>
#include <vector>
#include <jniapi.h>
#include <unzip.h>
#include <JavaString.h>
#include <BasicInfo.hpp>
#include <JavaFile.hpp>

extern "C" JNIEXPORT void JNICALL Java_com_zapp_acw_bll_PackageManager_unzipPackage (JNIEnv* env, jclass clazz, jstring package_path, jstring dest_path) {
	unzFile pack = unzOpen (JavaString (package_path).getString ().c_str ());
	if (pack == nullptr) {
		LOGE ("PackageManager::unzipPackage - Cannot open package to unzip!");
		return;
	}

	bool first = true;
	while (true) {
		//Locate the next file
		int32_t nextFileRes = first ? unzGoToFirstFile (pack) : unzGoToNextFile (pack);
		if (nextFileRes != UNZ_OK && nextFileRes != UNZ_END_OF_LIST_OF_FILE) {
			LOGE ("PackageManager::unzipPackage - Cannot locate file in package to unzip!");
			return;
		}
		first = false;

		//Read file info
		unz_file_info fileInfo;
		char fileNameBuffer[512];
		if (unzGetCurrentFileInfo (pack, &fileInfo, fileNameBuffer, 512, nullptr, 0, nullptr, 0) != UNZ_OK) {
			LOGE ("PackageManager::unzipPackage - Cannot read file info in package to unzip!");
			return;
		}

		if (fileInfo.size_filename >= 512) {
			LOGE ("PackageManager::unzipPackage - Filename too long in package to unzip!");
			return;
		}

		std::string fileName (&fileNameBuffer[0], &fileNameBuffer[fileInfo.size_filename]);

		//Unpack file to the destination
		if (unzOpenCurrentFile (pack) != UNZ_OK) {
			LOGE ("PackageManager::unzipPackage - Cannot open file in package to unzip!");
			return;
		}

		std::string destFilePath = JavaString (dest_path).getString () + "/" + fileName;
		FILE* destFile = fopen (destFilePath.c_str (), "wb");
		if (destFile == nullptr) {
			LOGE ("PackageManager::unzipPackage - Cannot create file at destination!");
			return;
		}

		int32_t chunkLen = 1024 * 1024;
		std::vector<uint8_t> buffer (chunkLen);
		int32_t readLen = 0;
		while ((readLen = unzReadCurrentFile (pack, &buffer[0], chunkLen)) != 0) {
			if (fwrite (&buffer[0], 1, readLen, destFile) != readLen) {
				LOGE ("PackageManager::unzipPackage - Cannot write file at destination!");
				return;
			}
		}

		fclose (destFile);

		if (unzCloseCurrentFile (pack) != UNZ_OK) {
			LOGE ("PackageManager::unzipPackage - Cannot close file in package to unzip!");
			return;
		}

		//Check last file
		if (nextFileRes == UNZ_END_OF_LIST_OF_FILE) { //If we reached the last file in the last cycle, then break
			break;
		}
	}

	unzClose (pack);
}

static std::vector<std::shared_ptr<BasicInfo>> readBasicPackageInfos (const std::string& dbDir) {
	JavaFile fileDB (dbDir);
//	NSFileManager *fileManager = [NSFileManager defaultManager];
//	NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants |
//											NSDirectoryEnumerationSkipsPackageDescendants |
//											NSDirectoryEnumerationSkipsHiddenFiles;
//	NSDirectoryEnumerator<NSURL*> *enumerator = [fileManager enumeratorAtURL:dbDir
//		includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
//		options:options
//		errorHandler:nil];

	std::vector<std::shared_ptr<BasicInfo>> result;
	for (const std::string& dirURL : fileDB.list ()) {
//		NSNumber *isDir = nil;
//		if ([dirURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil] == YES && [isDir boolValue]) {
//			std::shared_ptr<BasicInfo> basicInfo = BasicInfo::Create ([[dirURL path] UTF8String]);
//			if (basicInfo) {
//				result.push_back (basicInfo);
//			}
//		}
	}

	return result;
}
