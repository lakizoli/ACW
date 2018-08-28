//
//  UsedWords.cpp
//  adb
//
//  Created by Laki, Zoltan on 2018. 08. 28..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "UsedWords.hpp"
#include "BinarySerializer.hpp"

UsedWords::UsedWords (const std::string& path) :
	_path (path)
{
}

std::shared_ptr<UsedWords> UsedWords::Create (const std::string& path) {
	std::shared_ptr<UsedWords> uw (new UsedWords (path));
	
	if (ExistsFileInDatabase (path, "usedwords.dat")) {
		//Load words from file
		std::string usedWordsPath = path + "/usedwords.dat";
		std::fstream in (usedWordsPath, std::ios::in | std::ios::binary | std::ios::ate);
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
		
		//Deserialize words
		BinaryReader reader (data);

		reader.ReadArray ([uw] (const BinaryReader& reader) -> void {
			uw->_words.insert (reader.ReadWideString ());
		});
	}
	
	return uw;
}

bool UsedWords::Update (const std::string& path, const std::set<std::wstring>& usedWords) {
	std::vector<uint8_t> data;
	BinaryWriter writer (data);
	
	//Serialize words
	writer.WriteArray (usedWords, [] (BinaryWriter& writer, const std::wstring& item) -> void {
		writer.WriteWideString (item);
	});
	
	//Save crossword to file
	std::string usedWordsPath = path + "/usedwords.dat";
	std::fstream out (usedWordsPath, std::ios::out | std::ios::binary | std::ios::trunc);
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
