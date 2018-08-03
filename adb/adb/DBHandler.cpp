//
//  DBHandler.cpp
//  adb
//
//  Created by Laki, Zoltan on 2018. 08. 03..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "DBHandler.hpp"
#include <unzip.h>
#include <unistd.h>
#include <sqlite3.h>

bool DBHandler::ExistsFileInDatabase (const std::string& dbPath, const std::string& fileName) {
	std::string filePath = dbPath + "/" + fileName;
	return access (filePath.c_str (), R_OK) == 0;
}

bool DBHandler::UnpackFileToDatabase (const std::string& dbPath, const std::string& fileName) {
	//Check file existance
	if (ExistsFileInDatabase (dbPath, fileName)) {
		return true; //The file already exists, so have nothing to do...
	}
	
	//Extract file from package
	std::string packPath = dbPath + "/package.apkg";
	unzFile zipFile = unzOpen (packPath.c_str ());
	if (zipFile == nullptr) {
		return false;
	}
	
	struct AutoCloseZip {
		unzFile zipFile;
		AutoCloseZip (unzFile zipFile) : zipFile (zipFile) {}
		~AutoCloseZip () { unzClose (zipFile); }
	} autoCloseZip (zipFile);
	
	if (unzLocateFile (zipFile, fileName.c_str (), 2) != UNZ_OK) {
		return false;
	}
	
//	unz_file_info fileInfo;
//	if (unzGetCurrentFileInfo (zipFile, &fileInfo, nullptr, 0, nullptr, 0, nullptr, 0) != UNZ_OK) {
//		return false;
//	}
	
	if (unzOpenCurrentFile (zipFile) != UNZ_OK) {
		return false;
	}
	
	struct AutoCloseCurrentFile {
		unzFile zipFile;
		AutoCloseCurrentFile (unzFile zipFile) : zipFile (zipFile) {}
		~AutoCloseCurrentFile () { unzCloseCurrentFile (zipFile); }
	} autoCloseCurrentFile (zipFile);
	
	std::string outputPath = dbPath + "/" + fileName;
	std::fstream output (outputPath, std::ios::out | std::ios::binary | std::ios::trunc);
	if (!output) {
		return false;
	}
	
	std::vector<uint8_t> buffer (1024*1024);
	while (true) {
		int32_t readCount = unzReadCurrentFile (zipFile, &buffer[0], (unsigned) buffer.size ());
		if (readCount > 0) { //We read some bytes
			output.write ((const char*) &buffer[0], readCount);
			if (!output) {
				return false;
			}
		} else if (readCount < 0) { //some error occured during extraction
			return false;
		} else { //readCount == 0 - end reached succesfully
			break;
		}
	}
	
	return true;
}

DBHandler::SQLiteDB::SQLiteDB (const std::string& path) :
	path (path)
{
	if (sqlite3_open_v2 (path.c_str (), &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_NOMUTEX, nullptr) != SQLITE_OK) {
		db = nullptr;
	}
}

DBHandler::SQLiteDB::~SQLiteDB () {
	if (db) {
		sqlite3_close (db);
		db = nullptr;
	}
}

bool DBHandler::SQLiteDB::IsOpened () const {
	return db != nullptr;
}

bool DBHandler::ReadOneColumn (SQLiteDB& db, const std::string& cmd, uint32_t col, std::function<bool (const std::string& val)> callback) {
	sqlite3_stmt *db_stmt = nullptr;
	if (sqlite3_prepare (db.db, cmd.c_str (), (int) cmd.size (), &db_stmt, nullptr) != SQLITE_OK) {
		return false;
	}
	
	struct AutoFinalize {
		sqlite3_stmt *db_stmt;
		AutoFinalize (sqlite3_stmt *db_stmt) : db_stmt (db_stmt) {}
		~AutoFinalize () { sqlite3_finalize (db_stmt); }
	} autoFinalize (db_stmt);
	
	int32_t rc = 0;
	while ((rc = sqlite3_step (db_stmt)) == SQLITE_ROW) {
		int32_t valueLen = sqlite3_column_bytes (db_stmt, col);
		const char* val = (const char*) sqlite3_column_text (db_stmt, col);
		if (val == nullptr) {
			break;
		}
		
		if (!callback (std::string (val, valueLen))) {
			break;
		}
	}
	
	return true;
}
