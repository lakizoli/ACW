//
//  DBHandler.hpp
//  adb
//
//  Created by Laki, Zoltan on 2018. 08. 03..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef DBHandler_hpp
#define DBHandler_hpp

struct sqlite3;

class DBHandler {
//File functions
protected:
	static bool ExistsFileInDatabase (const std::string& dbPath, const std::string& fileName);
	static bool UnpackFileToDatabase (const std::string& dbPath, const std::string& fileName);
	
//SQLite functions
protected:
	struct SQLiteDB {
		std::string path;
		sqlite3 *db = nullptr;
		
		SQLiteDB (const std::string& path);
		~SQLiteDB ();
		bool IsOpened () const;
	};
	
	static bool ReadOneColumn (SQLiteDB& db, const std::string& cmd, uint32_t col, std::function<bool (const std::string& val)> callback);
	static bool ReadColumns (SQLiteDB& db, const std::string& cmd, uint32_t colCount, std::function<bool (const std::vector<std::string>& values)> callback);
};

#endif /* DBHandler_hpp */
