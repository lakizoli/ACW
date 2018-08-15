//
//  Cell.cpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "Cell.hpp"
#include "QuestionInfo.hpp"

std::shared_ptr<Cell> Cell::Create (uint32_t row, uint32_t col) {
	std::shared_ptr<Cell> cell (new Cell ());
	cell->_row = row;
	cell->_col = col;
	
	return cell;
}
