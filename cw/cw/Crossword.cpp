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

std::shared_ptr<Crossword> Crossword::Create (const std::string& name, uint32_t width, uint32_t height) {
	std::shared_ptr<Crossword> cw (new Crossword ());
	cw->_name = name;
	cw->_grid = Grid::Create (width, height);
	if (cw->_grid == nullptr) {
		return nullptr;
	}
	
	return cw;
}
