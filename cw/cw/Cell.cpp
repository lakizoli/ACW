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
	cell->_pos = CellPos { row, col };
	
	return cell;
}

std::shared_ptr<Cell> Cell::Deserialize (const BinaryReader& reader) {
	std::shared_ptr<Cell> cell (new Cell ());
	
	cell->_pos = CellPos {
		reader.ReadUInt32 (), //row
		reader.ReadUInt32 () //col
	};
	
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
	
	reader.ReadArray ([cell] (const BinaryReader& reader) -> void {
		cell->_startCellQuestionPositions.push_back (CellPos {
			reader.ReadUInt32 (), //row
			reader.ReadUInt32 () //col
		});
	});

	return cell;
}

void Cell::Serialize (BinaryWriter& writer) {
	writer.WriteUInt32 (_pos.row);
	writer.WriteUInt32 (_pos.col);
	writer.WriteUInt32 ((uint32_t) _flags);
	
	writer.WriteUInt8 (_value);
	writer.WriteUInt32 (_valueRefCount);
	
	bool hasQuestionInfo = _questionInfo != nullptr;
	writer.WriteBoolean (hasQuestionInfo);
	if (hasQuestionInfo) {
		_questionInfo->Serialize (writer);
	}

	writer.WriteArray (_startCellQuestionPositions, [] (BinaryWriter& writer, const CellPos& questionPos) -> void {
		writer.WriteUInt32 (questionPos.row);
		writer.WriteUInt32 (questionPos.col);
	});
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

void Cell::AddQuestionToStartCell (std::shared_ptr<Cell> questionCell) {
	_flags |= CellFlags::StartCell;
	_startCellQuestionPositions.push_back (CellPos {
		questionCell->_pos.row,
		questionCell->_pos.col
	});
}
