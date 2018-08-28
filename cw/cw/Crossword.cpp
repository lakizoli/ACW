//
//  Crossword.cpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "Crossword.hpp"
#include "Grid.hpp"
#include "BinarySerializer.hpp"

std::shared_ptr<Crossword> Crossword::Create (const std::string& name, uint32_t width, uint32_t height) {
	std::shared_ptr<Crossword> cw (new Crossword ());
	cw->_name = name;
	cw->_grid = Grid::Create (width, height);
	if (cw->_grid == nullptr) {
		return nullptr;
	}
	
	return cw;
}


std::shared_ptr<Crossword> Crossword::Load (const std::string& path) {
	//Load crossword from file
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
	
	//Deserialize crossword
	std::shared_ptr<Crossword> cw (new Crossword ());
	BinaryReader reader (data);
	
	cw->_name = reader.ReadString ();
	cw->_grid = Grid::Deserialize (reader);
	if (cw->_grid == nullptr) {
		return nullptr;
	}
	cw->_wordCount = reader.ReadUInt32 ();
	
	return cw;
}

bool Crossword::Save (const std::string& path) const {
	std::vector<uint8_t> data;
	BinaryWriter writer (data);
	
	//Serialize crossword
	writer.WriteString (_name);
	_grid->Serialize (writer);
	writer.WriteUInt32 (_wordCount);
	
	//Save crossword to file
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
