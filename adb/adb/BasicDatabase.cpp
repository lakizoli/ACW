//
//  BasicDatabase.cpp
//  adb
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "BasicDatabase.hpp"
#include "JsonObject.hpp"
#include <unzip.h>
#include <unistd.h>
#include <sqlite3.h>

BasicDatabase::BasicDatabase (const std::string& path) :
	_path (path),
	_deckID (0)
{
}

bool BasicDatabase::ExistsFileInDatabase (const std::string& fileName) const {
	std::string filePath = _path + "/" + fileName;
	return access (filePath.c_str (), R_OK) == 0;
}

bool BasicDatabase::UnpackFileToDatabase (const std::string& fileName) const {
	//Check file existance
	if (ExistsFileInDatabase (fileName)) {
		return true; //The file already exists, so have nothing to do...
	}
	
	//Extract file from package
	std::string packPath = _path + "/package.apkg";
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
	
	std::string outputPath = _path + "/" + fileName;
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

bool BasicDatabase::ReadOneColumn (sqlite3* db, const std::string& cmd, uint32_t col, std::function<bool (const std::string& val)> callback) {
	sqlite3_stmt *db_stmt = nullptr;
	if (sqlite3_prepare (db, cmd.c_str (), (int) cmd.size (), &db_stmt, nullptr) != SQLITE_OK) {
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

bool BasicDatabase::ReadBasicPackageInfo () {
	//Open database
	std::string collectionPath = _path + "/collection.anki2";
	sqlite3 *db = nullptr;
	if (sqlite3_open_v2 (collectionPath.c_str (), &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_NOMUTEX, nullptr) != SQLITE_OK) {
		return false;
	}
	
	struct AutoCloseDB {
		sqlite3 *db;
		AutoCloseDB (sqlite3 *db) : db (db) {}
		~AutoCloseDB () { sqlite3_close (db); }
	} autoCloseDB (db);
	
	//Select first deck id from cards table
	uint64_t deckID = 0;
	if (!ReadOneColumn (db, "SELECT did FROM cards GROUP BY did LIMIT 1", 0, [&deckID] (const std::string& val) -> bool {
		deckID = std::stoull (val);
		return false; //break;
	})) {
		return false;
	}
	
	_deckID = deckID;
	if (_deckID <= 0) {
		return false;
	}
	
	//Select decks from col table
	std::shared_ptr<JsonObject> jsonDeck;
	if (!ReadOneColumn (db, "SELECT decks FROM col LIMIT 1", 0, [deckID, &jsonDeck] (const std::string& val) -> bool {
		std::string deckKey = std::to_string (deckID);
		std::shared_ptr<JsonObject> json = JsonObject::Parse (val);
		if (json != nullptr && json->HasObject (deckKey)) {
			jsonDeck = json->GetObject (deckKey);
		}
		
		return false; //break
	})) {
		return false;
	}
	
	if (jsonDeck == nullptr) {
		return false;
	}
	
	if (jsonDeck->HasString ("name")) {
		_packageName = jsonDeck->GetString ("name");
		std::string::size_type pos = _packageName.rfind ("::");
		if (pos != std::string::npos && pos < _packageName.length () - 2) {
			_packageName = _packageName.substr (pos + 2);
		}
	} else {
		_packageName = "<empty>";
	}
	
	return true;
}

std::shared_ptr<BasicDatabase> BasicDatabase::Create (const std::string& path) {
	std::shared_ptr<BasicDatabase> result (new BasicDatabase (path));
	
	//Unzip Anki's sqlite db from packge
	if (!result->UnpackFileToDatabase ("collection.anki2")) {
		return nullptr;
	}
	
	//Read package name from database
	if (!result->ReadBasicPackageInfo ()) {
		return nullptr;
	}
	
	return result;
}
