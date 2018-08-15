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
	
//Implementation
	Crossword () = default;
	
//Construction
public:
	static std::shared_ptr<Crossword> Create (const std::string& name, uint32_t width, uint32_t height);
	
//Interface
public:
	std::shared_ptr<Grid> GetGrid () const {
		return _grid;
	}
};

#endif /* Crossword_hpp */
