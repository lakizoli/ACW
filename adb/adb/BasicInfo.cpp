//
//  BasicInfo.cpp
//  adb
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "BasicInfo.hpp"
#include "JsonObject.hpp"

BasicInfo::BasicInfo (const std::string& path) :
	_path (path)
{
}

bool BasicInfo::ReadBasicPackageInfo () {
	//Open database
	std::string collectionPath = _path + "/collection.anki2";
	SQLiteDB db (collectionPath);
	if (!db.IsOpened ()) {
		return false;
	}
	
	//Select used deck ids from cards table
	if (!ReadOneColumn (db, "SELECT did FROM cards GROUP BY did", 0, [&] (const std::string& val) -> bool {
		_deckIDs.insert (std::stoull (val));
		return true; //continue
	})) {
		return false;
	}
	
	if (_deckIDs.size () <= 0) {
		return false;
	}
	
	//Select decks from col table
	if (!ReadOneColumn (db, "SELECT decks FROM col LIMIT 1", 0, [&] (const std::string& val) -> bool {
		std::shared_ptr<JsonObject> json = JsonObject::Parse (val);
		if (json != nullptr) {
			json->IterateProperties ([&] (const std::string& name, const std::string& val, JsonDataType type) -> bool {
				if (type != JsonDataType::Object) {
					return true; //continue
				}
				
				uint64_t deckID = std::stoull (name);
				if (_deckIDs.find (deckID) == _deckIDs.end ()) { //Decks without any card
					return true; //continue
				}
				
				std::shared_ptr<JsonObject> jsonDeck = JsonObject::Parse (val);
				if (jsonDeck == nullptr) {
					return true; //continue
				}
				
				//Save deck
				std::shared_ptr<Deck> deck (std::make_shared<Deck> ());
				deck->id = deckID;

				if (jsonDeck->HasString ("name")) {
					deck->name = jsonDeck->GetString ("name");
					
					//extract package name
					if (_packageName.empty ()) {
						_packageName = deck->name;
						std::string::size_type posPack = _packageName.find ("::");
						if (posPack != std::string::npos && posPack < deck->name.length () - 2) {
							_packageName = _packageName.substr (0, posPack);
						}
					}
					
					//extract deck name
					std::string::size_type pos = deck->name.find ("::");
					if (pos != std::string::npos && pos < deck->name.length () - 2) {
						deck->name = deck->name.substr (pos + 2);
					}
					
					while ((pos = deck->name.rfind ("::")) != std::string::npos) {
						deck->name.replace (deck->name.begin () + pos, deck->name.begin () + (pos + 2), " - ");
					}
				} else {
					deck->name = "<empty>";
				}

				_decks.emplace (deckID, deck);
				return true; //continue
			});
		}
		
		return false; //break
	})) {
		return false;
	}
	
	return true;
}

std::shared_ptr<BasicInfo> BasicInfo::Create (const std::string& path) {
	std::shared_ptr<BasicInfo> result (new BasicInfo (path));
	
	//Unzip Anki's sqlite db from packge
	if (!UnpackFileToDatabase (result->_path, "collection.anki2")) {
		return nullptr;
	}
	
	//Read package name from database
	if (!result->ReadBasicPackageInfo ()) {
		return nullptr;
	}
	
	return result;
}
