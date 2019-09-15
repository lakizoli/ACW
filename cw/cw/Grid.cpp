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
#include "BinarySerializer.hpp"

bool Grid::IsCellFlagSet (uint32_t row, uint32_t col, CellFlags flag) const {
	return row < _height && col < _width && _cells[CellIndex (row, col)]->IsFlagSet (flag);
}

bool Grid::IsEmpty (uint32_t row, uint32_t col) const {
	return row < _height && col < _width && _cells[CellIndex (row, col)]->IsEmpty ();
}

std::shared_ptr<Cell> Grid::GetQuestionCellForPos (uint32_t row, uint32_t col, std::shared_ptr<Cell> reservedQuestionCell, bool isVerticalSearch) const {
	int32_t beforeCol = (int32_t)col - 1;
	if (beforeCol >= 0 && IsCellFlagSet (row, beforeCol, CellFlags::Question)) {
		std::shared_ptr<Cell> qCell = _cells[CellIndex (row, beforeCol)];
		uint32_t reservedCount = reservedQuestionCell != nullptr && qCell->GetPos () == reservedQuestionCell->GetPos () ? 1 : 0;
		std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
		if (qInfo != nullptr && qInfo->HasAvailableQuestionPlace (reservedCount)) {
			return qCell;
		}
	}

	int32_t beforeRow = (int32_t)row - 1;
	if (beforeRow >= 0 && IsCellFlagSet (beforeRow, col, CellFlags::Question)) {
		std::shared_ptr<Cell> qCell = _cells[CellIndex (beforeRow, col)];
		uint32_t reservedCount = reservedQuestionCell != nullptr && qCell->GetPos () == reservedQuestionCell->GetPos () ? 1 : 0;
		std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
		if (qInfo != nullptr && qInfo->HasAvailableQuestionPlace (reservedCount)) {
			return qCell;
		}
	}
	
	if (!isVerticalSearch) {
		uint32_t afterRow = row + 1;
		if (afterRow < _height && IsCellFlagSet (afterRow, col, CellFlags::Question)) {
			std::shared_ptr<Cell> qCell = _cells[CellIndex (afterRow, col)];
			uint32_t reservedCount = reservedQuestionCell != nullptr && qCell->GetPos () == reservedQuestionCell->GetPos () ? 1 : 0;
			std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
			if (qInfo != nullptr && qInfo->HasAvailableQuestionPlace (reservedCount)) {
				return qCell;
			}
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

std::shared_ptr<Grid> Grid::Deserialize (const BinaryReader& reader) {
	std::shared_ptr<Grid> grid (new Grid ());
	grid->_width = reader.ReadUInt32 ();
	grid->_height = reader.ReadUInt32 ();
	
	volatile bool readError = false;
	reader.ReadArray ([&readError, grid] (const BinaryReader& reader) -> void {
		std::shared_ptr<Cell> cell = Cell::Deserialize (reader);
		if (cell == nullptr) {
			readError = true;
		} else {
			grid->_cells.push_back (cell);
		}
	});
	
	if (readError) {
		return nullptr;
	}
	
	return grid;
}

void Grid::Serialize (BinaryWriter& writer) {
	writer.WriteUInt32 (_width);
	writer.WriteUInt32 (_height);
	writer.WriteArray (_cells, [] (BinaryWriter& writer, std::shared_ptr<Cell> cell) -> void {
		cell->Serialize (writer);
	});
}

void Grid::Dump () const {
	{
		std::stringstream ss;
		
		ss << "   ";
		
		for (uint32_t col = 0; col < _width; ++col) {
			if (col > 0) {
				ss << ",";
			}
			
			ss << "=Col(_)=";
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
				ss << "<nil(_)>";
			} else if (cell->IsFlagSet (CellFlags::Question)) {
				ss << "=Que(_)=";
			} else {
				uint8_t ch = (uint8_t) cell->GetValue ();
				if (ch > 128) {
					ch = '?';
				}
				
				uint32_t refCount = cell->GetValueRefCount ();
				ss << "= " << (char) ch << " (" << (refCount > 1 ? std::to_string (refCount) : "_") << ")=";
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

void Grid::AdvanceToTheNextAvailablePos (uint32_t& row, uint32_t& col, bool& wasDiag) {
	while (row < _height && col < _width && !IsEmpty (row, col)) {
		if (wasDiag) { //We take the diagonal value first
			col = row = col + 2;
			if (row >= _height || col >= _width) {
				wasDiag = false;
				row = col = 1;
			}
		} else { //We take the normal values either
			if (col == 0) { //First col
				col = row + 1;
				if (col >= _width) { //After last col
					row = col - _width + 1;
					col = _width - 1;
				} else {
					row = 0;
				}
			} else {
				++row;
				if (row >= _height) { //After last row
					col = col + row;
					if (col >= _width) { //After last col
						row = col - _width + 1;
						col = _width - 1;
					} else {
						row = 0;
					}
				} else {
					--col;
				}
			}
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
	
	res.questionCell = GetQuestionCellForPos (row, startCol, nullptr, false);
	if (res.questionCell != nullptr) { //We have a valid question pos available
		for (uint32_t iCol = startCol; iCol < _width; ++iCol) {
			if (IsCellFlagSet (row, iCol, CellFlags::Question)) {
				break;
			}
			
			res.cellsAvailable.push_back (_cells[CellIndex (row, iCol)]);
		}
	}
	
	return res;
}

Grid::FindQuestionResult Grid::FindVerticalQuestionForPos (uint32_t row, uint32_t col, std::shared_ptr<Cell> reservedQuestionCell) const {
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
	
	res.questionCell = GetQuestionCellForPos (startRow, col, reservedQuestionCell, true);
	if (res.questionCell != nullptr) { //We have a valid question pos available
		for (uint32_t iRow = startRow; iRow < _height; ++iRow) {
			if (IsCellFlagSet (iRow, col, CellFlags::Question)) {
				break;
			}
			
			res.cellsAvailable.push_back (_cells[CellIndex (iRow, col)]);
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
