//
//  CardList.hpp
//  adb
//
//  Created by Laki, Zoltan on 2018. 08. 02..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef CardList_hpp
#define CardList_hpp

class CardList {
	std::string _path;
	uint64_t _deckID;

	CardList (const std::string& path, uint64_t deckID);
	
public:
	static std::shared_ptr<CardList> Create (const std::string& path, uint64_t deckID);
};

#endif /* CardList_hpp */
