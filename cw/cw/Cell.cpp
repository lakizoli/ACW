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
#include "BinarySerializer.hpp"

std::shared_ptr<Cell> Cell::Create (uint32_t row, uint32_t col) {
	std::shared_ptr<Cell> cell (new Cell ());
	cell->_row = row;
	cell->_col = col;
	
	return cell;
}

std::shared_ptr<Cell> Cell::Deserialize (const BinaryReader& reader) {
	std::shared_ptr<Cell> cell (new Cell ());
	
	cell->_row = reader.ReadUInt32 ();
	cell->_col = reader.ReadUInt32 ();
	cell->_flags = (CellFlags) reader.ReadUInt32 ();
	
	cell->_value = reader.ReadUInt8 ();
	cell->_valueRefCount = reader.ReadUInt32 ();
	
	bool hasQuestionInfo = reader.ReadBoolean ();
	if (hasQuestionInfo) {
		cell->_questionInfo = QuestionInfo::Deserialize (reader);
		if (cell->_questionInfo == nullptr) {
			return nullptr;
		}
	}

	return cell;
}

void Cell::Serialize (BinaryWriter& writer) {
	writer.WriteUInt32 (_row);
	writer.WriteUInt32 (_col);
	writer.WriteUInt32 ((uint32_t) _flags);
	
	writer.WriteUInt8 (_value);
	writer.WriteUInt32 (_valueRefCount);
	
	bool hasQuestionInfo = _questionInfo != nullptr;
	writer.WriteBoolean (hasQuestionInfo);
	if (hasQuestionInfo) {
		_questionInfo->Serialize (writer);
	}
}

void Cell::ConfigureAsEmptyQuestion () {
	_questionInfo = QuestionInfo::Create ();
	_flags |= CellFlags::Question;
}

void Cell::SetValue (uint8_t value) {
	_flags |= CellFlags::Value;
	_value = value;
	++_valueRefCount;
}
