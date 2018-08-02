//
//  CardList.cpp
//  adb
//
//  Created by Laki, Zoltan on 2018. 08. 02..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "CardList.hpp"

CardList::CardList (const std::string& path, uint64_t deckID) :
	_path (path),
	_deckID (deckID)
{
}

std::shared_ptr<CardList> CardList::Create (const std::string& path, uint64_t deckID) {
	std::shared_ptr<CardList> cardList (new CardList (path, deckID));
	
	//TODO: ...
	
	return cardList;
}
