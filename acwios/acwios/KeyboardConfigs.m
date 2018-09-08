//
//  KeyboardConfigs.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "KeyboardConfigs.h"

#pragma mark - KeyboardConfig

@implementation KeyboardConfig {
	NSSet<NSString*> *_basicKeys;
	NSDictionary<NSNumber*, NSNumber*> *_extraKeyCountsOfBasicPages;
	
	NSUInteger _extraPageCount;
	NSMutableDictionary<NSNumber*, NSString*> *_extraKeyTitles;
	NSMutableDictionary<NSNumber*, NSString*> *_extraKeyValues;
}

//////////////////////////////////////////////////////////////////////
//Private functions
//////////////////////////////////////////////////////////////////////

-(void) collectKeyboardKeys {
	__block NSMutableSet<NSString*> *basicKeys = [NSMutableSet<NSString*> new];
	__block NSMutableDictionary<NSNumber*, NSNumber*> *extraKeyCountsOfBasicPages = [NSMutableDictionary<NSNumber*, NSNumber*> new];
	
	for (NSUInteger page = 0;page < BASIC_PAGE_COUNT;++page) {
		__block NSUInteger extraKeyCountOnPage = 0;
		
		for (uint32_t row = 0;row < 4;++row) {
			NSArray<NSString*>* keys = nil;
			NSArray<NSNumber*>* weights = nil;
			if ([self rowKeys:row page:page outKeys:&keys outWeights:&weights] == YES) {
				[keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
					[basicKeys addObject:key];
					
					if ([key hasPrefix:@"Ex"]) { //Extra key
						++extraKeyCountOnPage;
					}
				}];
			}
		}

		if (extraKeyCountOnPage > 0) {
			[extraKeyCountsOfBasicPages setObject:[NSNumber numberWithUnsignedInteger:extraKeyCountOnPage]
										   forKey:[NSNumber numberWithUnsignedInteger:page]];
		}
	}
	
	_basicKeys = basicKeys;
	_extraKeyCountsOfBasicPages = extraKeyCountsOfBasicPages;
}

-(NSInteger) extraKeyIDFromPage:(NSUInteger)page keyIndex:(NSInteger)keyIndex {
	return (NSInteger) page * 1000 + keyIndex;
}

//////////////////////////////////////////////////////////////////////
//Interface
//////////////////////////////////////////////////////////////////////
				 
-(id) init {
	self = [super init];
	if (self) {
		
		[self collectKeyboardKeys];
		
		_extraPageCount = 0;
		_extraKeyTitles = [NSMutableDictionary<NSNumber*, NSString*> new];
		_extraKeyValues = [NSMutableDictionary<NSNumber*, NSString*> new];
	}
	return self;
}

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page < BASIC_PAGE_COUNT) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector (_cmd)]
									 userInfo:nil];
	}
	
	//Extra page
	switch (row) {
		case 0:
			*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", BACKSPACE];
			*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,      @2.0];
			return YES;
		case 1:
			*outKeys    = @[@"Ex11", @"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17", @"Ex18", @"Ex19", ENTER];
			*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,  @2.0];
			return YES;
		case 2:
			*outKeys    = @[@"Ex20", @"Ex21", @"Ex22", @"Ex23", @"Ex24", @"Ex25", @"Ex26"];
			*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
			return YES;
		case 3:
			*outKeys    = @[SWITCH, SPACEBAR, TURNOFF];
			*outWeights = @[  @1.0,     @3.0,    @1.0];
			return YES;
		default:
			break;
	}
	
	return NO;
}

-(NSSet<NSString*>*) collectExtraKeys:(NSSet<NSString*>*)keysToCheck {
	__block NSMutableSet<NSString*>* notFoundKeys = [NSMutableSet<NSString*> new];
	
	[keysToCheck enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		NSString *keyToCheck = [obj uppercaseString];
		if ([self->_basicKeys containsObject:keyToCheck] != YES) {
			[notFoundKeys addObject:keyToCheck];
		}
	}];
	
	return notFoundKeys;
}

-(NSInteger) getExtraKeyID:(NSString*)key page:(NSUInteger)page {
	if ([key hasPrefix:@"Ex"]) {
		NSInteger extraKeyID = [self extraKeyIDFromPage:page keyIndex:[[key substringFromIndex:2] integerValue]];
		NSNumber *numberForExtraKeyID = [NSNumber numberWithInteger:extraKeyID];
		if ([_extraKeyValues objectForKey:numberForExtraKeyID] != nil && [_extraKeyTitles objectForKey:numberForExtraKeyID] != nil) {
			return extraKeyID;
		}
	}
	
	return 0;
}

-(NSString*) getValueForExtraKeyID:(NSInteger)extraKeyID {
	if (extraKeyID > 0) { //Extra key
		return [_extraKeyValues objectForKey:[NSNumber numberWithInteger: extraKeyID]];
	}
	
	return nil;
}

-(NSString*) getTitleForExtraKeyID:(NSInteger)extraKeyID {
	if (extraKeyID > 0) { //Extra key
		return [_extraKeyTitles objectForKey:[NSNumber numberWithInteger: extraKeyID]];
	}
	
	return nil;
}

-(NSUInteger) getPageCount {
	return BASIC_PAGE_COUNT + _extraPageCount;
}

-(void) addExtraPages:(NSSet<NSString*>*)notFoundKeys {
	//Copy keys to alloc
	__block NSMutableArray<NSString*> *keysToAlloc = [NSMutableArray<NSString*> new];
	[notFoundKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		[keysToAlloc addObject:obj];
	}];
	
	//Fill extra keys on basic pages first
	NSArray<NSNumber*> *sortedKeys = [[_extraKeyCountsOfBasicPages allKeys] sortedArrayUsingComparator:
									  ^NSComparisonResult (NSNumber *page1, NSNumber *page2) {
		if ([page1 unsignedIntegerValue] < [page2 unsignedIntegerValue]) {
			return NSOrderedAscending;
		} else if ([page1 unsignedIntegerValue] == [page2 unsignedIntegerValue]) {
			return NSOrderedSame;
		}
		
		return NSOrderedDescending;
	}];

	[sortedKeys enumerateObjectsUsingBlock:^(NSNumber *pageNum, NSUInteger idx, BOOL *stop) {
		NSUInteger page = [pageNum unsignedIntegerValue];
		NSUInteger availableKeyCount = [[self->_extraKeyCountsOfBasicPages objectForKey:pageNum] unsignedIntegerValue];
		
		NSUInteger allocatableKeyCount = availableKeyCount > [keysToAlloc count] ? [keysToAlloc count] : availableKeyCount; //min
		for (NSUInteger i = 0; i < allocatableKeyCount; ++i) {
			NSInteger extraKeyID = [self extraKeyIDFromPage:page keyIndex:i+1];
			NSString *key = [keysToAlloc objectAtIndex:i];
			
			[self->_extraKeyValues setObject:key forKey:[NSNumber numberWithInteger:extraKeyID]];
			[self->_extraKeyTitles setObject:key forKey:[NSNumber numberWithInteger:extraKeyID]];
		}
		
		for (NSUInteger i = 0; i < allocatableKeyCount; ++i) {
			[keysToAlloc removeObjectAtIndex:0];
		}
	}];
	
	//Fill remaining not found keys on etxra pages
	//TODO: ...
	
//	[notFoundKeys enumerateObjectsUsingBlock:^(NSString *key, BOOL *stop) {
//
//	}];
	//TODO: implement addExtraPages...
}

@end

#pragma mark - US Keyboard

@implementation USKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"Q", @"W", @"E", @"R", @"T", @"Y", @"U", @"I", @"O", @"P", BACKSPACE];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", BACKSPACE];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"A", @"S", @"D", @"F", @"G", @"H", @"J", @"K", @"L", ENTER];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,  @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"Z", @"X", @"C", @"V", @"B", @"N", @"M"];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex10", @"Ex11", @"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16"];
				*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
				return YES;
			}
			break;
		case 3:
			if (page == PAGE_ALPHA || page == PAGE_NUM) {
				*outKeys    = @[SWITCH, SPACEBAR, TURNOFF];
				*outWeights = @[  @1.0,     @3.0,    @1.0];
				return YES;
			}
			break;
		default:
			break;
	}
	
	return NO;
}

@end
