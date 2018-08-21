//
//  Package.mm
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "Package.h"
#include <cw.hpp>

@implementation Card

-(id) init {
	self = [super init];
	if (self) {
		_cardID = 0;
		_noteID = 0;
		_modelID = 0;
		_fieldValues = [NSMutableArray<NSString*> new];
	}
	return self;
}

@end

@implementation Field

-(id) init {
	self = [super init];
	if (self) {
		_idx = 0;
	}
	return self;
}

@end

@implementation GeneratorInfo

-(id) init {
	self = [super init];
	if (self) {
		_decks = [NSMutableArray<Deck*> new];
		_cards = [NSMutableArray<Card*> new];
		_fields = [NSMutableArray<Field*> new];
	}
	return self;
}

@end

@implementation Deck

-(id) init {
	self = [super init];
	if (self) {
		_deckID = 0;
	}
	return self;
}

@end

@implementation Package

-(id) init {
	self = [super init];
	if (self) {
		_decks = [NSMutableArray<Deck*> new];
	}
	return self;
}

@end

@implementation SavedCrossword {
	std::shared_ptr<Crossword> _cw;
}

-(id) init {
	self = [super init];
	if (self) {
		_width = 0;
		_height = 0;
		_wordCount = 0;
	}
	return self;
}

-(void) loadDB {
	_cw = Crossword::Load ([[_path path] UTF8String]);
}

-(void) unloadDB {
	_cw = nullptr;
}

-(std::shared_ptr<Cell>) getCell:(uint32_t)row col:(uint32_t)col {
	if (_cw == nullptr) {
		return nullptr;
	}
	
	std::shared_ptr<Grid> grid = _cw->GetGrid ();
	if (grid == nullptr) {
		return nullptr;
	}
	
	if (row >= grid->GetHeight ()) {
		return nullptr;
	}
	
	if (col >= grid->GetWidth ()) {
		return nullptr;
	}
	
	return grid->GetCell (row, col);
}

-(BOOL) isStartCell:(std::shared_ptr<Cell>)cell {
	//TODO: ...
	return NO;
}

-(enum CWCellType) getCellTypeInRow:(uint32_t)row col:(uint32_t)col {
	std::shared_ptr<Cell> cell = [self getCell:row col:col];
	if (cell == nullptr) {
		return CWCellType_Unknown;
	}
	
	//Spacer cell
	if (cell->IsEmpty ()) {
		return CWCellType_Spacer;
	}
	
	//Question cell
	if (cell->IsFlagSet (CellFlags::Question)) {
		std::shared_ptr<QuestionInfo> qInfo = cell->GetQuestionInfo ();
		if (qInfo == nullptr) {
			return CWCellType_Unknown;
		}
		
		const std::vector<QuestionInfo::Question>& questions = qInfo->GetQuestions ();
		switch (questions.size ()) {
			case 1:
				return CWCellType_SingleQuestion;
			case 2:
				return CWCellType_DoubleQuestion;
			default:
				break;
		}
		
		return CWCellType_Unknown;
	}
	
	//Handle start letters
	if ([self isStartCell:cell]) {
		//TODO: ...
	}

	return CWCellType_Letter;
}

@end
