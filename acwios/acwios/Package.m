//
//  Package.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "Package.h"

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
