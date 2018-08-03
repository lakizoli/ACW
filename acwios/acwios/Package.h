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

@interface Card : NSObject
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
