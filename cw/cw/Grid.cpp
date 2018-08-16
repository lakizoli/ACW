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

bool Grid::IsCellFlagSet (uint32_t row, uint32_t col, CellFlags flag) const {
	return row < _height && col < _width && _cells[CellIndex (row, col)]->IsFlagSet (flag);
}

bool Grid::IsEmpty (uint32_t row, uint32_t col) const {
	return row < _height && col < _width && _cells[CellIndex (row, col)]->IsEmpty ();
}

std::shared_ptr<Cell> Grid::GetQuestionCellForPos (uint32_t row, uint32_t col) const {
	int32_t beforeCol = (int32_t)col - 1;
	if (beforeCol >= 0 && IsCellFlagSet (row, beforeCol, CellFlags::Question)) {
		std::shared_ptr<Cell> qCell = _cells[CellIndex (row, beforeCol)];
		std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
		if (qInfo != nullptr && qInfo->HasAvailableQuestionPlace ()) {
			return qCell;
		}
	}

	int32_t beforeRow = (int32_t)row - 1;
	if (beforeRow >= 0 && IsCellFlagSet (beforeRow, col, CellFlags::Question)) {
		std::shared_ptr<Cell> qCell = _cells[CellIndex (beforeRow, col)];
		std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
		if (qInfo != nullptr && qInfo->HasAvailableQuestionPlace ()) {
			return qCell;
		}
	}
	
	uint32_t afterRow = row + 1;
	if (afterRow < _height && IsCellFlagSet (afterRow, col, CellFlags::Question)) {
		std::shared_ptr<Cell> qCell = _cells[CellIndex (afterRow, col)];
		std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
		if (qInfo != nullptr && qInfo->HasAvailableQuestionPlace ()) {
			return qCell;
		}
	}

	return nullptr;
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

void Grid::Dump () const {
	{
		std::stringstream ss;
		
		ss << "   ";
		
		for (uint32_t col = 0; col < _width; ++col) {
			if (col > 0) {
				ss << ",";
			}
			
			ss << "=Col=";
		}
		
		std::cout << ss.str () << std::endl;
	}
	
	for (uint32_t row = 0; row < _height; ++row) {
		std::stringstream ss;
		
		ss << "R: ";
		
		for (uint32_t col = 0; col < _width; ++col) {
			if (col > 0) {
				ss << ",";
			}
			
			std::shared_ptr<Cell> cell = _cells[CellIndex (row, col)];
			if (cell->IsEmpty ()) {
				ss << "<nil>";
			} else if (cell->IsFlagSet (CellFlags::Question)) {
				ss << "=Que=";
			} else {
				ss << "==" << (char)cell->GetValue () << "==";
			}
		}
		
		std::cout << ss.str () << std::endl;
	}
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

void Grid::AdvanceToTheNextAvailablePos (uint32_t& row, uint32_t& col) {
	while (row < _height && col < _width && !IsEmpty (row, col)) {
		++col;
		if (col >= _width) {
			++row;
			col = 0;
		}
	}
}

Grid::FindQuestionResult Grid::FindHorizontalQuestionForPos (uint32_t row, uint32_t col) const {
	//Find last available question field in the row
	uint32_t startCol = 0;
	for (int32_t iCol = (int32_t)col; iCol >= 0; --iCol) {
		//Test pos for word start
		int32_t beforeCol = iCol - 1;
		if (IsCellFlagSet (row, beforeCol, CellFlags::Question)) { //The current word starts at the last separator, or at 0 pos
			startCol = iCol;
			break;
		}
	}
	
	//Check validity of found pos (get an available question pos)
	FindQuestionResult res;
	
	res._questionCell = GetQuestionCellForPos (row, startCol);
	if (res._questionCell != nullptr) { //We have a valid question pos available
		for (uint32_t iCol = startCol; iCol < _width; ++iCol) {
			if (IsCellFlagSet (row, iCol, CellFlags::Question)) {
				break;
			}
			
			res._cellsAvailable.push_back (_cells[CellIndex (row, iCol)]);
		}
	}
	
	return res;
}

Grid::FindQuestionResult Grid::FindVerticalQuestionForPos (uint32_t row, uint32_t col) const {
	//Find last available question field in the column
	uint32_t startRow = 0;
	for (int32_t iRow = (int32_t)row; iRow >= 0; --iRow) {
		//Test pos for word start
		int32_t beforeRow = iRow - 1;
		if (IsCellFlagSet (beforeRow, col, CellFlags::Question)) { //The current word starts at the last separator, or at 0 pos
			startRow = iRow;
			break;
		}
	}
	
	//Check validity of found pos (get an available question pos)
	FindQuestionResult res;
	
	res._questionCell = GetQuestionCellForPos (startRow, col);
	if (res._questionCell != nullptr) { //We have a valid question pos available
		for (uint32_t iRow = startRow; iRow < _height; ++iRow) {
			if (IsCellFlagSet (iRow, col, CellFlags::Question)) {
				break;
			}
			
			res._cellsAvailable.push_back (_cells[CellIndex (iRow, col)]);
		}
	}
	
	return res;
}

bool Grid::SetCellToFreeQuestionCell (uint32_t row, uint32_t col) {
	if (row >= _height || col >= _width) {
		return false;
	}
	
	_cells[CellIndex (row, col)]->ConfigureAsEmptyQuestion ();
	return true;
}
