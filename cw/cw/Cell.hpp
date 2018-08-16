//
//  Cell.hpp
//  cw
//
//  Created by Laki, Zoltan on 2018. 08. 15..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef Cell_hpp
#define Cell_hpp

#include "CellFlags.hpp"

class QuestionInfo;

class Cell {
	uint32_t _row = 0;
	uint32_t _col = 0;
	CellFlags _flags = CellFlags::Empty;
	
	uint8_t _value = 0;
	uint32_t _valueRefCount = 0;
	
	std::shared_ptr<QuestionInfo> _questionInfo;

//Implementation
	Cell () = default;
	
//Construction
public:
	static std::shared_ptr<Cell> Create (uint32_t row, uint32_t col);
	
//Interface
public:
	uint32_t GetRow () const { return _row; }
	uint32_t GetCol () const { return _col; }
	
	CellFlags GetFlags () const { return _flags; }
	bool IsEmpty () const { return (_flags & CellFlags::HasSomeValue) == CellFlags::Empty; }
	bool IsFlagSet (CellFlags flag) const { return (_flags & flag) == flag; }
	
	uint8_t GetValue () const { return _value; }
	uint32_t GetValueRefCount () const { return _valueRefCount; }
	
	std::shared_ptr<QuestionInfo> GetQuestionInfo () const { return _questionInfo; }
	
//Generation interface
public:
	void ConfigureAsEmptyQuestion ();
	void SetValue (uint8_t value);
};

#endif /* Cell_hpp */
