//
//  Package.mm
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "Package.h"
#import <UIKit/UIKit.h>
#include <cw.hpp>
#include <adb.hpp>

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
		_usedWords = [NSMutableArray<NSString*> new];
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
	}
	return self;
}

-(void) eraseFromDisk {
	NSFileManager *man = [NSFileManager defaultManager];
	NSError *err = nil;

	//Delete used words from db
	if ([_words count] > 0) {
		NSString *packagePath = [[_path path] stringByDeletingLastPathComponent];
		std::shared_ptr<UsedWords> usedWords = UsedWords::Create ([packagePath UTF8String]);
		if (usedWords) {
			__block std::set<std::wstring> updatedWords = usedWords->GetWords ();
			
			[_words enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
				NSData *objData = [obj dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
				std::wstring wordToErase ((const wchar_t*) [objData bytes], [objData length] / sizeof (wchar_t));
				updatedWords.erase (wordToErase);
			}];
			
			UsedWords::Update ([packagePath UTF8String], updatedWords);
		}
	}
	
	//Delete filled values
	NSURL *filledValuesPath = [self filledValuesPath];
	err = nil;
	if ([man removeItemAtURL:filledValuesPath error:&err] != YES) {
		NSLog (@"Cannot delete crossword's filled values at path: %@, error: %@", filledValuesPath, err);
	}

	//Delete crossword
	err = nil;
	if ([man removeItemAtURL:_path error:&err] != YES) {
		NSLog (@"Cannot delete crossword at path: %@, error: %@", _path, err);
	}
}

-(void) loadDB {
	_cw = Crossword::Load ([[_path path] UTF8String]);
}

-(void) unloadDB {
	_cw = nullptr;
}

- (NSURL*)filledValuesPath {
	NSURL *pureFileName = [_path URLByDeletingPathExtension];
	return [pureFileName URLByAppendingPathExtension:@"filledValues"];
}

-(void) saveFilledValues:(NSMutableDictionary<NSIndexPath*, NSString*>*)filledValues {
	//Remove original file if exists
	NSFileManager *man = [NSFileManager defaultManager];
	NSURL *path = [self filledValuesPath];

	if ([man fileExistsAtPath:[path path]]) {
		NSError *err = nil;
		if ([man removeItemAtURL:path error:&err] == NO) {
			//log...
			return;
		}
	}
	
	//Convert filled values to serializable one
	__block NSMutableDictionary<NSString*, NSString*> *ser = [NSMutableDictionary<NSString*, NSString*> new];
	[filledValues enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		NSString *keyValue = [NSString stringWithFormat:@"%ld_%ld", (long)key.section, key.row];
		[ser setObject:obj forKey:keyValue];
	}];
	
	//Save filled values
	NSError* errWrite = nil;
	if ([ser writeToURL:path error:&errWrite] == NO) {
		//log...
		return;
	}
}

-(void) loadFilledValuesInto:(NSMutableDictionary<NSIndexPath*, NSString*>*)filledValues {
	//Clear original content
	[filledValues removeAllObjects];
	
	//Load content
	NSURL *path = [self filledValuesPath];
	BOOL isDirectory = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:[path path] isDirectory:&isDirectory] && isDirectory == NO) {
		NSDictionary<NSString*, NSString*>* dict = [NSDictionary dictionaryWithContentsOfURL:path];
		[dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
			NSRange range = [key rangeOfString:@"_"];
			if (range.location != NSNotFound) {
				NSString *valSection = [key substringToIndex:range.location];
				NSString *valRow = [key substringFromIndex:range.location + 1];
				NSInteger section = [valSection intValue];
				NSInteger row = [valRow intValue];
				
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
				[filledValues setObject:obj forKey:indexPath];
			}
		}];
	}
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

-(uint32_t) getCellTypeInRow:(uint32_t)row col:(uint32_t)col {
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
		
		return CWCellType_Spacer;
	}
	
	//Handle start letters
	if (cell->IsFlagSet (CellFlags::StartCell)) {
		uint32_t cellTypeRes = CWCellType_Unknown;
		
		for (const CellPos& qPos : cell->GetStartCellQuestionPositions ()) {
			std::shared_ptr<Cell> qCell = [self getCell:qPos.row col:qPos.col];
			if (qCell == nullptr) {
				continue;
			}

			const CellPos& cPos = cell->GetPos ();
			if (cPos.row < qPos.row && cPos.col == qPos.col) { //Start cell is above question cell
				cellTypeRes |= CWCellType_Start_LeftRight_Top;
			} else if (cPos.row > qPos.row && cPos.col == qPos.col) { //Start cell is below question cell
				std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
				if (qInfo == nullptr) {
					continue;
				}
				
				const std::vector<QuestionInfo::Question>& qs = qInfo->GetQuestions ();
				if (qs.size () >= 1) {
					switch (qs[qs.size () - 1].dir) {
						case QuestionInfo::Direction::BottomDown:
							cellTypeRes |= CWCellType_Start_TopDown_Bottom;
							break;
						case QuestionInfo::Direction::BottomRight:
							cellTypeRes |= CWCellType_Start_LeftRight_Bottom;
							break;
						default:
							break;
					}
				}
			} else if (cPos.row == qPos.row && cPos.col < qPos.col) { //Start cell is on the left side of question cell
				cellTypeRes |= CWCellType_Start_TopDown_Left;
			} else if (cPos.row == qPos.row && cPos.col > qPos.col) { //Start cell is on the right side of question cell
				std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
				if (qInfo == nullptr) {
					continue;
				}
				
				const std::vector<QuestionInfo::Question>& qs = qInfo->GetQuestions ();
				if (qs.size () > 1) {
					switch (qs[0].dir) {
						case QuestionInfo::Direction::RightDown:
							cellTypeRes |= CWCellType_Start_TopDown_Right;
							break;
						case QuestionInfo::Direction::Right:
							cellTypeRes |= CWCellType_Start_TopRight;
							break;
						default:
							break;
					}
					
					if (qs[1].dir == QuestionInfo::Direction::Right) {
						cellTypeRes |= CWCellType_Start_BottomRight;
					}
				} else if (qs.size () == 1) {
					switch (qs[0].dir) {
						case QuestionInfo::Direction::RightDown:
							cellTypeRes |= CWCellType_Start_TopDown_Right;
							break;
						case QuestionInfo::Direction::Right:
							cellTypeRes |= CWCellType_Start_FullRight;
							break;
						default:
							break;
					}
				}
			}
		}
		
		return cellTypeRes;
	}

	return CWCellType_Letter;
}

-(BOOL) isStartCell:(uint32_t)row col:(uint32_t)col {
	std::shared_ptr<Cell> cell = [self getCell:row col:col];
	return (cell != nullptr && cell->IsFlagSet (CellFlags::StartCell));
}

-(NSString*) getCellsQuestion:(uint32_t)row col:(uint32_t)col questionIndex:(uint32_t)questionIndex {
	std::shared_ptr<Cell> cell = [self getCell:row col:col];
	if (cell != nullptr && cell->IsFlagSet (CellFlags::Question)) {
		std::shared_ptr<QuestionInfo> qInfo = cell->GetQuestionInfo ();
		if (qInfo != nullptr) {
			const std::vector<QuestionInfo::Question>& qs = qInfo->GetQuestions ();
			if (qs.size () > questionIndex) {
				const std::wstring& qStr = qs[questionIndex].question;
				NSUInteger len = qStr.length () * sizeof (wchar_t);
				return [[NSString alloc] initWithBytes:qStr.c_str () length:len encoding:NSUTF32LittleEndianStringEncoding];
			}
		}
	}
	
	return nil;
}

-(NSString*) getCellsValue:(uint32_t)row col:(uint32_t)col {
	std::shared_ptr<Cell> cell = [self getCell:row col:col];
	if (cell != nullptr && cell->IsFlagSet (CellFlags::Value)) {
		return [NSString stringWithFormat:@"%c", cell->GetValue ()];
	}
	
	return nil;
}

-(uint32_t) getCellsSeparators:(uint32_t)row col:(uint32_t)col {
	uint32_t seps = CWCellSeparator_None;

	std::shared_ptr<Cell> cell = [self getCell:row col:col];
	if (cell != nullptr) {
		if (cell->IsFlagSet (CellFlags::LeftSeparator)) {
			seps |= CWCellSeparator_Left;
		}
		
		if (cell->IsFlagSet (CellFlags::TopSeparator)) {
			seps |= CWCellSeparator_Top;
		}

		std::shared_ptr<Cell> rightCell = [self getCell:row col:col + 1];
		if (rightCell != nullptr && rightCell->IsFlagSet (CellFlags::LeftSeparator)) { //If the right neighbour has a left separator!
			seps |= CWCellSeparator_Right;
		}
		
		std::shared_ptr<Cell> bottomCell = [self getCell:row + 1 col:col];
		if (bottomCell != nullptr && bottomCell->IsFlagSet (CellFlags::TopSeparator)) { //If the bottom neighbour has a top separator!
			seps |= CWCellSeparator_Bottom;
		}
	}
	
	return seps;
}

@end
