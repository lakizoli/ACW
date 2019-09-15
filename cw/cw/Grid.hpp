//
//  Grid.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef Grid_hpp
#define Grid_hpp

#include "cw.hpp"

class BinaryReader;
class BinaryWriter;

class Grid {
	uint32_t _width = 0;
	uint32_t _height = 0;
	std::vector<std::shared_ptr<Cell>> _cells; ///< The cells in row major order: 1:[row0, col0], 2:[row1, col0] etc...
	
//Implementation
	Grid () = default;
	uint32_t CellIndex (uint32_t row, uint32_t col) const { return col * _height + row; }
	bool IsCellFlagSet (uint32_t row, uint32_t col, CellFlags flag) const;
	bool IsEmpty (uint32_t row, uint32_t col) const;
	std::shared_ptr<Cell> GetQuestionCellForPos (uint32_t row, uint32_t col, std::shared_ptr<Cell> reservedQuestionCell, bool isVerticalSearch) const;
	
//Construction
public:
	static std::shared_ptr<Grid> Create (uint32_t width, uint32_t height);
	
	static std::shared_ptr<Grid> Deserialize (const BinaryReader& reader);
	void Serialize (BinaryWriter& writer);
	
//Interface
public:
	uint32_t GetWidth () const { return _width; }
	uint32_t GetHeight () const { return _height; }
	std::shared_ptr<Cell> GetCell (uint32_t row, uint32_t col) const { return _cells[CellIndex (row, col)]; }
	
	void Dump () const;
	
//Generation interface
public:
	bool AllCellsAreFilled () const;
	void AdvanceToTheNextAvailablePos (uint32_t& row, uint32_t& col, bool& wasDiag);
	
	struct FindQuestionResult {
		std::shared_ptr<Cell> questionCell;
		std::vector<std::shared_ptr<Cell>> cellsAvailable; ///< This is the list of available cells continuously...
		
		bool FoundAvailableQuestion () const { return questionCell != nullptr; }
	};
	
	FindQuestionResult FindHorizontalQuestionForPos (uint32_t row, uint32_t col) const;
	FindQuestionResult FindVerticalQuestionForPos (uint32_t row, uint32_t col, std::shared_ptr<Cell> reservedQuestionCell) const;
	
	bool SetCellToFreeQuestionCell (uint32_t row, uint32_t col);
};

#endif /* Grid_hpp */
