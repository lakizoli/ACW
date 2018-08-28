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
	uint32_t _wordCount = 0;
	
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
	
	uint32_t GetWordCount () const { return _wordCount; }
	void SetWordCount (uint32_t wordCount) { _wordCount = wordCount; }
};

#endif /* Crossword_hpp */
