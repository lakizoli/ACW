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

class BinaryReader;
class BinaryWriter;
class QuestionInfo;

struct CellPos {
	uint32_t row = 0;
	uint32_t col = 0;
	
	bool operator == (const CellPos& chk) const { return row == chk.row && col == chk.col; }
};

class Cell {
	CellPos _pos;
	CellFlags _flags = CellFlags::Empty;
	
	wchar_t _value = 0;
	uint32_t _valueRefCount = 0;
	
	std::shared_ptr<QuestionInfo> _questionInfo;
	std::vector<CellPos> _startCellQuestionPositions;

//Implementation
	Cell () = default;
	
//Construction
public:
	static std::shared_ptr<Cell> Create (uint32_t row, uint32_t col);
	
	static std::shared_ptr<Cell> Deserialize (const BinaryReader& reader);
	void Serialize (BinaryWriter& writer);

//Interface
public:
	const CellPos& GetPos () const { return _pos; }
	
	CellFlags GetFlags () const { return _flags; }
	bool IsEmpty () const { return (_flags & CellFlags::HasSomeValue) == CellFlags::Empty; }
	bool IsFlagSet (CellFlags flag) const { return (_flags & flag) == flag; }
	
	wchar_t GetValue () const { return _value; }
	uint32_t GetValueRefCount () const { return _valueRefCount; }
	
	std::shared_ptr<QuestionInfo> GetQuestionInfo () const { return _questionInfo; }
	const std::vector<CellPos>& GetStartCellQuestionPositions () const { return _startCellQuestionPositions; }
	
//Generation interface
public:
	void ConfigureAsEmptyQuestion ();
	void SetValue (wchar_t value);
	void SetSeparator (CellFlags separatorFlag);
	void AddQuestionToStartCell (std::shared_ptr<Cell> questionCell);
};

#endif /* Cell_hpp */
