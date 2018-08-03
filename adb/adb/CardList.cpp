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
#include "JsonArray.hpp"

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
	
	//Select model id from deck id
	{
		std::string sql = "SELECT notes.mid"
			" FROM cards"
			" INNER JOIN notes"
			" ON notes.id = cards.nid"
			" WHERE did = " + std::to_string (_deckID) +
			" GROUP BY notes.mid";
		if (!ReadOneColumn (db, sql, 0, [&] (const std::string& val) -> bool {
			_modelID = std::stoull (val);
			return false; //break
		})) {
			return false;
		}
		
		if (_modelID <= 0) {
			return false;
		}
	}

	//Query model
	std::shared_ptr<JsonObject> jsonModel;
	if (!ReadOneColumn (db, "SELECT models FROM col LIMIT 1", 0, [modelID = _modelID, &jsonModel] (const std::string& val) -> bool {
		std::shared_ptr<JsonObject> json = JsonObject::Parse (val);
		if (json != nullptr) {
			std::string key = std::to_string (modelID);
			if (json->HasObject (key)) {
				jsonModel = json->GetObject (key);
			}
		}
		
		return false; //break
	})) {
		return false;
	}
	
	if (jsonModel == nullptr) {
		return false;
	}

	//Collect fields from model
	{
		if (!jsonModel->HasArray ("flds")) {
			return false;
		}
		
		std::shared_ptr<JsonArray> arr = jsonModel->GetArray ("flds");
		if (arr == nullptr) {
			return false;
		}
		
		for (int32_t i = 0, iEnd = arr->GetCount (); i < iEnd; ++i) {
			if (!arr->HasObjectAtIndex (i)) {
				return false;
			}
			
			std::shared_ptr<JsonObject> obj = arr->GetObjectAtIndex (i);
			if (obj == nullptr) {
				return false;
			}
			
			std::shared_ptr<Field> field (std::make_shared<Field> ());
			if (obj->HasString ("name")) {
				field->name = obj->GetString ("name");
			}
			
			if (obj->GetUInt32 ("ord")) {
				field->idx = obj->GetUInt32 ("ord");
			}
			
			_fields.emplace (field->idx, field);
		}
	}
	
	//Select cards
	{
		std::string sql = "SELECT cards.id, cards.nid, notes.flds, notes.sfld"
			" FROM cards"
			" INNER JOIN notes"
			" ON notes.id = cards.nid"
			" WHERE did = " + std::to_string (_deckID);
		if (!ReadColumns (db, sql, 4, [&] (const std::vector<std::string>& colValues) -> bool {
			//...
			return true; //continue
		})) {
			return false;
		}
	}
	
	return true;
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
