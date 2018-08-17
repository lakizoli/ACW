//
//  WordBank.cpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "WordBank.hpp"
#include "QueryWords.hpp"

uint32_t WordBank::WordList::IntersectionCount (const std::string& w1, const std::string& w2) {
	uint32_t count = 0;

	for (uint8_t ch1 : w1) {
		for (uint8_t ch2 : w2) {
			if (ch1 == ch2) {
				++count;
			}
		}
	}
	
	return count;
}

void WordBank::WordList::AddWord (uint32_t index, uint32_t length, const std::string& word, std::shared_ptr<QueryWords> allWords) {
	uint32_t sumIntersectionCount = 0;
	for (uint32_t i = 0, iEnd = allWords->GetCount (); i < iEnd; ++i) {
		if (i == index) {
			continue;
		}
		
		const std::string& checkWord = allWords->GetWord (i);
		if (checkWord == word) {
			continue;
		}
		
		sumIntersectionCount += IntersectionCount (word, checkWord);
	}
	
	uint32_t importance = 0xFFFFFFFF - sumIntersectionCount; //The words with more intersection have to be former in the map!
	
	auto it = _indices.find (importance);
	if (it == _indices.end ()) {
		_indices.emplace (importance, std::vector<uint32_t> { index });
	} else {
		it->second.push_back (index);
	}
}

bool WordBank::EnumerateWordsOfIndices (const std::vector<uint32_t>& indices, EnumWords callback) const {
	for (auto it = indices.begin (); it != indices.end (); ++it) {
		uint32_t wordIdx = *it;
		if (!callback (wordIdx, _words->GetWord (wordIdx))) {
			return false; //break
		}
	}
	
	return true; //continue
}

std::shared_ptr<WordBank> WordBank::Create (std::shared_ptr<QueryWords> words) {
	std::shared_ptr<WordBank> bank (new WordBank ());
	bank->_words = words;
	if (bank->_words->GetCount () <= 0) {
		return nullptr;
	}
	
	for (uint32_t i = 0, iEnd = bank->_words->GetCount (); i < iEnd; ++i) {
		std::string word = bank->_words->GetWord (i);

		uint32_t len = (uint32_t) word.length ();
		auto itLen = bank->_search.find (len);
		if (itLen == bank->_search.end ()) { //New length found
			std::shared_ptr<WordList> wordList (std::make_shared<WordList> ());
			wordList->AddWord (i, len, word, words);
			bank->_search.emplace (len, wordList);
		} else { //This length is found already
			itLen->second->AddWord (i, len, word, words);
		}
	}
	
	//TODO: ... Sort words in word lists
	
	return bank;
}

uint32_t WordBank::GetMinLength () const {
	return _search.begin ()->first;
}

uint32_t WordBank::GetMaxLength () const {
	auto it = _search.end ();
	--it;
	return it->first;
}

bool WordBank::ContainsLength (uint32_t len) const {
	auto it = _search.find (len);
	return it != _search.end ();
}

void WordBank::EnumerateWords (uint32_t len, EnumWords callback) const {
	auto it = _search.find (len);
	if (it != _search.end ()) {
		std::shared_ptr<WordList> wordList = it->second;
		for (auto& itIndices : wordList->_indices) {
			if (!EnumerateWordsOfIndices (itIndices.second, callback)) {
				return; //break enumeration
			}
		}
	}
}

//void WordBank::EnumerateWords (uint32_t len, uint8_t firstLetter, EnumWords callback) const {
//	auto it = _search.find (len);
//	if (it != _search.end ()) {
//		std::shared_ptr<WordList> wordList = it->second;
//		
//		WordKey startKey { firstLetter, 0 };
//		
//		WordKey endKey;
//		endKey.firstLetter = firstLetter + 1;
//		
//		for (auto itIndices = wordList->_indices.lower_bound (startKey); itIndices != wordList->_indices.upper_bound (endKey); ++itIndices) {
//			if (!EnumerateWordsOfIndices (itIndices->second, callback)) {
//				return; //break enumeration
//			}
//		}
//	}
//}
//
//void WordBank::EnumerateWords (uint32_t len, uint8_t firstLetter, uint8_t secondLetter, EnumWords callback) const {
//	auto it = _search.find (len);
//	if (it != _search.end ()) {
//		std::shared_ptr<WordList> wordList = it->second;
//		
//		auto itIndices = wordList->_indices.find (WordKey { firstLetter, secondLetter });
//		if (itIndices != wordList->_indices.end ()) {
//			if (!EnumerateWordsOfIndices (itIndices->second, callback)) {
//				return; //break enumeration
//			}
//		}
//	}
//}
