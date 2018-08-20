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

@interface SavedCrossword : NSObject

@property (strong) NSURL *path;
@property (strong) NSString *packageName;
@property (strong) NSString *name;

@property (assign) uint32_t width;
@property (assign) uint32_t height;
@property (assign) uint32_t wordCount;

@end
