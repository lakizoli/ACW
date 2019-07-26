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
#include "BinarySerializer.hpp"

uint32_t WordBank::WordList::IntersectionCount (const std::wstring& w1, const std::wstring& w2) {
	uint32_t count = 0;

	for (wchar_t ch1 : w1) {
		for (wchar_t ch2 : w2) {
			if (ch1 == ch2) {
				++count;
			}
		}
	}
	
	return count;
}

void WordBank::WordList::AddWord (uint32_t index, uint32_t length, const std::wstring& word, std::shared_ptr<QueryWords> allWords) {
	uint32_t sumIntersectionCount = 0;
	for (uint32_t i = 0, iEnd = allWords->GetCount (); i < iEnd; ++i) {
		if (i == index) {
			continue;
		}
		
		const std::wstring& checkWord = allWords->GetWord (i);
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
		
		std::set<uint32_t> spacePositions;
		std::wstring wordWithoutSpaces = RemoveSpacesAndCollectPlaces (_words->GetWord (wordIdx), spacePositions);

		if (!callback (wordIdx, wordWithoutSpaces, spacePositions)) {
			return false; //break
		}
	}
	
	return true; //continue
}

bool WordBank::IsSeparatorOrSpace (wchar_t ch) {
	return (ch >= 0x09 && ch <= 0x0D) ||
		ch == 0x20 || ch == 0xA0 || ch == 0x1680 || ch == 0x180E ||
		(ch >= 0x2000 && ch <= 0x200A) ||
		ch == 0x2028 || ch == 0x2029 || ch == 0x202F || ch == 0x205F || ch == 0x3000;
}

uint32_t WordBank::LengthOfWordWithoutSpaces (const std::wstring& word) {
	uint32_t count_space = (uint32_t) std::count_if (word.begin (), word.end (), [] (wchar_t ch) -> bool {
		return IsSeparatorOrSpace (ch);
	});
	
	return (uint32_t) word.length () - count_space;
}

std::wstring WordBank::RemoveSpacesAndCollectPlaces (const std::wstring& word, std::set<uint32_t>& spacePositions) const {
	std::wstring res;
	
	for (uint32_t pos = 0, posEnd = (uint32_t) word.length (); pos < posEnd; ++pos) {
		wchar_t ch = word[pos];
		if (IsSeparatorOrSpace (ch)) {
			uint32_t currentLen = (uint32_t) res.length ();
			if (currentLen > 0) {
				spacePositions.insert (currentLen);
			}
		} else {
			res.push_back (ch);
		}
	}
	
	return res;
}

std::shared_ptr<WordBank> WordBank::Create (std::shared_ptr<QueryWords> words, std::function<bool (float)> progressCallback) {
	std::shared_ptr<WordBank> bank (new WordBank ());
	bank->_words = words;
	if (bank->_words->GetCount () <= 0) {
		return nullptr;
	}
	
	for (uint32_t i = 0, iEnd = bank->_words->GetCount (); i < iEnd; ++i) {
		const std::wstring& word = bank->_words->GetWord (i);

		uint32_t len = LengthOfWordWithoutSpaces (word);
		auto itLen = bank->_search.find (len);
		if (itLen == bank->_search.end ()) { //New length found
			std::shared_ptr<WordList> wordList (std::make_shared<WordList> ());
			wordList->AddWord (i, len, word, words);
			bank->_search.emplace (len, wordList);
		} else { //This length is found already
			itLen->second->AddWord (i, len, word, words);
		}
		
		if (progressCallback) {
			float progress = (float) i / (float) iEnd;
			if (!progressCallback (progress)) {
				return nullptr; //break generation
			}
		}
	}
	
	//TODO: ... Sort words in word lists
	
	if (progressCallback) {
		progressCallback (1.0f);
	}
	
	return bank;
}

std::shared_ptr<WordBank> WordBank::Load (const std::string& path, std::shared_ptr<QueryWords> words, std::function<bool (float)> progressCallback) {
	//Load wordbank from file
	std::fstream in (path, std::ios::in | std::ios::binary | std::ios::ate);
	if (!in) {
		return nullptr;
	}
	
	size_t len = in.tellg ();
	if (!in) {
		return nullptr;
	}
	
	if (len <= 0) {
		return nullptr;
	}
	
	in.seekg (0, std::ios::beg);
	if (!in) {
		return nullptr;
	}
	
	std::vector<uint8_t> data (len);
	in.read ((char*) &data[0], data.size ());
	if (!in) {
		return nullptr;
	}
	
	in.close ();
	if (!in) {
		return nullptr;
	}
	
	//Deserialize wordbank
	std::shared_ptr<WordBank> bank (new WordBank ());
	bank->_words = words;
	
	BinaryReader reader (data);

	reader.ReadArray ([bank] (const BinaryReader& reader) -> void {
		uint32_t searchKey = reader.ReadUInt32 ();
		
		std::shared_ptr<WordList> wordList (new WordList ());
		reader.ReadArray ([wordList] (const BinaryReader& reader) -> void {
			uint32_t indexKey = reader.ReadUInt32 ();
			
			std::vector<uint32_t> indices;
			reader.ReadArray ([&indices] (const BinaryReader& reader) -> void {
				indices.push_back (reader.ReadUInt32 ());
			});
			
			wordList->_indices.emplace (indexKey, indices);
		});
		
		bank->_search.emplace (searchKey, wordList);
	});
	
	if (progressCallback) {
		progressCallback (1.0f);
	}
	
	return bank;
}

bool WordBank::Save (const std::string& path) const {
	std::vector<uint8_t> data;
	BinaryWriter writer (data);
	
	//Serialize wordbank
	writer.WriteArray (_search, [] (BinaryWriter& writer, const std::pair<uint32_t, std::shared_ptr<WordList>>& searchItem) -> void {
		writer.WriteUInt32 (searchItem.first);
		writer.WriteArray (searchItem.second->_indices, [] (BinaryWriter& writer, const std::pair<uint32_t, std::vector<uint32_t>>& indexItem) -> void {
			writer.WriteUInt32 (indexItem.first);
			writer.WriteArray (indexItem.second, [] (BinaryWriter& writer, uint32_t val) -> void {
				writer.WriteUInt32 (val);
			});
		});
	});
	
	//Save wordbank to file
	std::fstream out (path, std::ios::out | std::ios::binary | std::ios::trunc);
	if (!out) {
		return false;
	}
	
	out.write ((const char*) &data[0], data.size ());
	if (!out) {
		return false;
	}
	
	out.close ();
	if (!out) {
		return false;
	}
	
	return true;
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
