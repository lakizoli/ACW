//
//  Grid.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef Grid_hpp
#define Grid_hpp

class Cell;

class Grid {
	uint32_t _width = 0;
	uint32_t _height = 0;
	std::vector<std::shared_ptr<Cell>> _cells; ///< The cells in row major order: 1:[row0, col0], 2:[row1, col0] etc...
	
//Implementation
	Grid () = default;
	uint32_t CellIndex (uint32_t row, uint32_t col) const { return col * _height + row; }
	bool IsEmpty (uint32_t row, uint32_t col) const;
	
//Construction
public:
	static std::shared_ptr<Grid> Create (uint32_t width, uint32_t height);
	
//Interface
public:
	uint32_t GetWidth () const { return _width; }
	uint32_t GetHeight () const { return _height; }
	std::shared_ptr<Cell> GetCell (uint32_t row, uint32_t col) const { return _cells[CellIndex (row, col)]; }
	
//Generation interface
public:
	bool AllCellsAreFilled () const;
	
	struct FindQuestionResult {
		std::shared_ptr<Cell> _questionCell;
		std::vector<std::shared_ptr<Cell>> _cellsAvailable; ///< This is the list of available cells continuously...
		
		bool FoundAvailableQuestion () const { return _questionCell != nullptr; }
	};
	
	FindQuestionResult FindHorizontalQuestionForPos (uint32_t row, uint32_t col) const;
	FindQuestionResult FindVerticalQuestionForPos (uint32_t row, uint32_t col) const;
};

#endif /* Grid_hpp */
