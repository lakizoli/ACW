//
//  BasicInfo.hpp
//  adb
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef BasicInfo_hpp
#define BasicInfo_hpp

#include "DBHandler.hpp"

class BasicInfo : public DBHandler {
public:
	struct Deck {
		uint64_t id = 0;
		std::string name;
	};
	
private:
	std::string _path;
	std::string _packageName;
	std::set<uint64_t> _deckIDs;
	std::map<uint64_t, std::shared_ptr<Deck>> _decks;
	
	BasicInfo (const std::string& path);
	bool ReadBasicPackageInfo ();

public:
	static std::shared_ptr<BasicInfo> Create (const std::string& path);
	
public:
	const std::string& GetPath () const { return _path; }
	const std::string& GetPackageName () const { return _packageName; }
	const std::set<uint64_t> GetDeckIDs () const { return _deckIDs; }
	const std::map<uint64_t, std::shared_ptr<Deck>>& GetDecks () const { return _decks; }
};

#endif /* BasicInfo_hpp */
