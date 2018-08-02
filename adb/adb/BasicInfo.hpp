//
//  BasicInfo.hpp
//  adb
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef BasicInfo_hpp
#define BasicInfo_hpp

struct sqlite3;

class BasicInfo {
	std::string _path;
	uint64_t _deckID;
	std::string _packageName;
	
	BasicInfo (const std::string& path);
	
	bool ExistsFileInDatabase (const std::string& fileName) const;
	bool UnpackFileToDatabase (const std::string& fileName) const;
	static bool ReadOneColumn (sqlite3* db, const std::string& cmd, uint32_t col, std::function<bool (const std::string& val)> callback);
	bool ReadBasicPackageInfo ();

public:
	static std::shared_ptr<BasicInfo> Create (const std::string& path);
	
public:
	const std::string& GetPath () const { return _path; }
	uint64_t GetDeckID () const { return _deckID; }
	const std::string& GetPackageName () const { return _packageName; }
};

#endif /* BasicInfo_hpp */
