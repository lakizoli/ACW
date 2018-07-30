//
//  BasicDatabase.hpp
//  adb
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef BasicDatabase_hpp
#define BasicDatabase_hpp

struct sqlite3;

class BasicDatabase {
	std::string _path;
	
	BasicDatabase (const std::string& path);
	
	bool ExistsFileInDatabase (const std::string& fileName) const;
	bool UnpackFileToDatabase (const std::string& fileName) const;
	static bool ReadOneColumn (sqlite3* db, const std::string& cmd, uint32_t col, std::function<bool (const std::string& val)> callback);
	bool ReadPackageName () const;

public:
	static std::shared_ptr<BasicDatabase> Create (const std::string& path);
};

#endif /* BasicDatabase_hpp */
