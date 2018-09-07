//
//  Crossword.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef Crossword_hpp
#define Crossword_hpp

class Grid;

class Crossword {
	std::string _name;
	std::shared_ptr<Grid> _grid;
	std::set<std::wstring> _words; ///< The list of words used in this crossword.
	std::set<wchar_t> _usedKeys; ///< The keys used in words.
	
//Implementation
	Crossword () = default;
	
//Construction
public:
	static std::shared_ptr<Crossword> Create (const std::string& name, uint32_t width, uint32_t height);
	
	static std::shared_ptr<Crossword> Load (const std::string& path);
	bool Save (const std::string& path) const;
	
//Interface
public:
	const std::string& GetName () const { return _name; }
	std::shared_ptr<Grid> GetGrid () const { return _grid; }
	
	const std::set<std::wstring>& GetWords () const { return _words; }
	void SetWords (const std::set<std::wstring>& words) { _words = words; }
	
	const std::set<wchar_t>& GetUsedKeys () const { return _usedKeys; }
	void SetUsedKeys (const std::set<wchar_t>& usedKeys) { _usedKeys = usedKeys; }
};

#endif /* Crossword_hpp */
