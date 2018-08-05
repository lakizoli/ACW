//
//  CardList.hpp
//  adb
//
//  Created by Laki, Zoltan on 2018. 08. 02..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef CardList_hpp
#define CardList_hpp

#include "DBHandler.hpp"

class CardList : public DBHandler {
public:
	struct Field {
		std::string name = "<empty>";
		uint32_t idx = 0;
	};
	
	struct Card {
		uint64_t cardID = 0;
		uint64_t noteID = 0;
		uint64_t modelID = 0;
		std::vector<std::string> fields;
		std::string solutionField;
	};
	
private:
	std::string _path;
	uint64_t _deckID = 0;
	uint64_t _modelID = 0;
	std::map<uint32_t, std::shared_ptr<Field>> _fields;
	std::map<uint64_t, std::shared_ptr<Card>> _cards;

	CardList (const std::string& path, uint64_t deckID);
	bool Read ();
	
public:
	static std::shared_ptr<CardList> Create (const std::string& path, uint64_t deckID);
	
public:
	const std::string& GetPath () const { return _path; }
	uint64_t GetDeckID () const { return _deckID; }
	uint64_t GetModelID () const { return _modelID; }
	const std::map<uint32_t, std::shared_ptr<Field>>& GetFields () const { return _fields; }
	const std::map<uint64_t, std::shared_ptr<Card>>& GetCards () const { return _cards; }
};

#endif /* CardList_hpp */
