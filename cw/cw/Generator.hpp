//
//  Generator.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef Generator_hpp
#define Generator_hpp

class Crossword;
class WordBank;
class QueryWords;
class Cell;

class Generator {
	std::string _path;
	std::string _name;
	uint32_t _width = 0;
	uint32_t _height = 0;
	std::shared_ptr<QueryWords> _questions;
	std::shared_ptr<WordBank> _answers;
	
//Implementation
	Generator () = default;
	
	struct InsertWordRes {
		bool inserted = false;
		bool questionAdded = false;
		uint32_t insertedWordLen = 0;
		uint32_t insertedWordIndex = 0;
	};
	
	InsertWordRes InsertWordIntoCells (const std::vector<std::shared_ptr<Cell>>& cells, std::set<std::string>& usedWords) const;
	void ConfigureQuestionInCell (std::shared_ptr<Cell> questionCell, std::shared_ptr<Cell> firstLetterCell,
								  std::shared_ptr<Cell> secondLetterCell, uint32_t questionIndex) const;
	
//Construction
public:
	static std::shared_ptr<Generator> Create (const std::string& path, const std::string& name,
											  uint32_t width, uint32_t height,
											  std::shared_ptr<QueryWords> questions, std::shared_ptr<QueryWords> answers);
	
//Interface
public:
	std::shared_ptr<Crossword> Generate () const;
};

#endif /* Generator_hpp */
