//
//  CardList.cpp
//  adb
//
//  Created by Laki, Zoltan on 2018. 08. 02..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "CardList.hpp"
#include "JsonObject.hpp"

CardList::CardList (const std::string& path, uint64_t deckID) :
	_path (path),
	_deckID (deckID)
{
}

bool CardList::Read () {
	//Open database
	std::string collectionPath = _path + "/collection.anki2";
	SQLiteDB db (collectionPath);
	if (!db.IsOpened ()) {
		return false;
	}
	
	//Select fields from model
	std::shared_ptr<JsonObject> jsonModel;
	if (!ReadOneColumn (db, "SELECT models FROM col LIMIT 1", 0, [deckID = _deckID, &jsonModel] (const std::string& val) -> bool {
		std::shared_ptr<JsonObject> json = JsonObject::Parse (val);
		if (json != nullptr) {
			json->IterateProperties ([deckID, &jsonModel] (const std::string& name, const std::string& val, JsonDataType type) -> bool  {
				if (type == JsonDataType::Object) {
					std::shared_ptr<JsonObject> obj = JsonObject::Parse (val);
					if (obj && obj->HasUInt64 ("did") && obj->GetUInt64 ("did") == deckID) {
						jsonModel = obj;
						return false; //break
					}
				}
				
				return true; //continue;
			});
		}
		
		return false; //break
	})) {
		return false;
	}
	
	if (jsonModel == nullptr) {
		return false;
	}

	
	//Select cards
	
	return false;
}

std::shared_ptr<CardList> CardList::Create (const std::string& path, uint64_t deckID) {
	std::shared_ptr<CardList> cardList (new CardList (path, deckID));
	
	//Unzip Anki's sqlite db from packge
	if (!UnpackFileToDatabase (cardList->_path, "collection.anki2")) {
		return nullptr;
	}
	
	//Read cards from database
	if (!cardList->Read ()) {
		return nullptr;
	}
	
	return cardList;
}
