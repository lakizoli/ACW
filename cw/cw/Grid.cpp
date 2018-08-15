//
//  Grid.cpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#include "prefix.hpp"
#include "Grid.hpp"
#include "Cell.hpp"
#include "QuestionInfo.hpp"

bool Grid::IsEmpty (uint32_t row, uint32_t col) const {
	return (_cells[CellIndex (row, col)]->GetFlags () & CellFlags::HasSomeValue) == CellFlags::Empty;
}

std::shared_ptr<Grid> Grid::Create (uint32_t width, uint32_t height) {
	if (width <= 0 || height <= 0) {
		return nullptr;
	}
	
	std::shared_ptr<Grid> grid (new Grid ());
	grid->_width = width;
	grid->_height = height;
	
	grid->_cells.resize (width * height);
	for (uint32_t col = 0; col < width; ++col) {
		for (uint32_t row = 0; row < height; ++row) {
			grid->_cells[grid->CellIndex (row, col)] = Cell::Create (row, col);
		}
	}
	
	return grid;
}

bool Grid::AllCellsAreFilled () const {
	for (uint32_t col = 0; col < _width; ++col) {
		for (uint32_t row = 0; row < _height; ++row) {
			if (IsEmpty (row, col)) {
				return false;
			}
		}
	}
	
	return true;
}

Grid::FindQuestionResult Grid::FindHorizontalQuestionForPos (uint32_t row, uint32_t col) const {
	FindQuestionResult res;
	
	//Find last available question field in the row
	for (int32_t iCol = (int32_t)col; iCol >= 0; --iCol) {
		//TODO: check all available question configuration!...
	}
	
	return res;
}

Grid::FindQuestionResult Grid::FindVerticalQuestionForPos (uint32_t row, uint32_t col) const {
	//TODO: implement
	return FindQuestionResult ();
}

