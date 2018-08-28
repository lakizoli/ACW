//
//  UsedWords.hpp
//  adb
//
//  Created by Laki, Zoltan on 2018. 08. 28..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef UsedWords_hpp
#define UsedWords_hpp

#include "DBHandler.hpp"

class UsedWords : public DBHandler {
	std::string _path;
	std::set<std::wstring> _words;
	
	UsedWords (const std::string& path);
	
public:
	static std::shared_ptr<UsedWords> Create (const std::string& path);
	static bool Update (const std::string& path, const std::set<std::wstring>& usedWords);
	
public:
	const std::string& GetPath () const { return _path; }
	const std::set<std::wstring>& GetWords () const { return _words; }
};

#endif /* UsedWords_hpp */
