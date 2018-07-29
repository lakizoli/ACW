//
//  BasicDatabase.cpp
//  adb
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "BasicDatabase.hpp"
#include <unzip.h>

std::shared_ptr<BasicDatabase> BasicDatabase::Create (const std::string& path) {
	//Unzip Anki's sqlite db from packge
	std::string packPath = path + "/package.apkg";
	unzFile zipFile = unzOpen (packPath.c_str ());
	if (zipFile == nullptr) {
		return nullptr;
	}
	
	if (unzClose (zipFile) != UNZ_OK) {
		//Log...
	}
	
	//Read package name from database
	//...
	
	return nullptr;
}
