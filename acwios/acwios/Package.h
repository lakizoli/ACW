//
//  Package.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Package;
@class Deck;
@class GeneratorInfo;
@class Field;

@interface Card : NSObject

@property (assign) NSUInteger cardID;
@property (assign) NSUInteger noteID;
@property (assign) NSUInteger modelID;
@property (strong) NSMutableArray<NSString*> *fieldValues;
@property (strong) NSString *solutionFieldValue;

@end

@interface Field : NSObject

@property (assign) NSUInteger idx;
@property (strong) NSString *name;

@end

@interface GeneratorInfo : NSObject

//Database properties
@property (strong) NSMutableArray<Deck*> *decks;
@property (strong) NSMutableArray<Card*> *cards;
@property (strong) NSMutableArray<Field*> *fields;
@property (strong) NSMutableArray<NSString*> *usedWords;

//Configured properties
@property (strong) NSString *crosswordName;
@property (assign) NSUInteger width;
@property (assign) NSUInteger height;
@property (assign) NSUInteger questionFieldIndex;
@property (assign) NSUInteger solutionFieldIndex;

@end

@interface Deck : NSObject

@property (weak) Package *package;
@property (assign) NSUInteger deckID;
@property (strong) NSString *name;

@end

@interface Package : NSObject

@property (strong) NSURL *path;
@property (strong) NSString *name;
@property (strong) NSMutableArray<Deck*> *decks;

@end

enum CWCellType : uint32_t {
	CWCellType_Unknown					= 0x0000,
	
	CWCellType_SingleQuestion			= 0x0001,
	CWCellType_DoubleQuestion			= 0x0002,
	CWCellType_Spacer					= 0x0004,
	CWCellType_Letter					= 0x0008,
	
	CWCellType_Start_TopDown_Right		= 0x0010,
	CWCellType_Start_TopDown_Left		= 0x0020,
	CWCellType_Start_TopDown_Bottom		= 0x0040,
	
	CWCellType_Start_TopRight			= 0x0080,
	CWCellType_Start_FullRight			= 0x0100,
	CWCellType_Start_BottomRight		= 0x0200,

	CWCellType_Start_LeftRight_Top		= 0x0400,
	CWCellType_Start_LeftRight_Bottom	= 0x0800,
	
	CWCellType_HasValue					= 0x0FF8
};

enum CWCellSeparator : uint32_t {
	CWCellSeparator_None	= 0x0000,
	
	CWCellSeparator_Left	= 0x0001,
	CWCellSeparator_Top		= 0x0002,
	CWCellSeparator_Right	= 0x0004,
	CWCellSeparator_Bottom	= 0x0008,
	
	CWCellSeparator_All		= 0x000F
};

@interface SavedCrossword : NSObject

@property (strong) NSURL *path;
@property (strong) NSString *packageName;
@property (strong) NSString *name;

@property (assign) uint32_t width;
@property (assign) uint32_t height;
@property (assign) uint32_t wordCount;

-(void) loadDB;
-(void) unloadDB;

-(void) saveFilledValues:(NSMutableDictionary<NSIndexPath*, NSString*>*)filledValues;
-(void) loadFilledValuesInto:(NSMutableDictionary<NSIndexPath*, NSString*>*)filledValues;

-(uint32_t) getCellTypeInRow:(uint32_t)row col:(uint32_t)col;
-(BOOL) isStartCell:(uint32_t)row col:(uint32_t)col;
-(NSString*) getCellsQuestion:(uint32_t)row col:(uint32_t)col questionIndex:(uint32_t)questionIndex;
-(NSString*) getCellsValue:(uint32_t)row col:(uint32_t)col;
-(uint32_t) getCellsSeparators:(uint32_t)row col:(uint32_t)col;

@end
