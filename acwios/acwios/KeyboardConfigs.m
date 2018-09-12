//
//  KeyboardConfigs.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "KeyboardConfigs.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Layouts taken from: https://docs.microsoft.com/en-us/globalization/windows-keyboard-layouts
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - KeyboardConfig

@implementation KeyboardConfig {
	NSSet<NSString*> *_basicKeys;
	NSDictionary<NSNumber*, NSNumber*> *_extraKeyCountsOfBasicPages;
	
	NSUInteger _extraPageCount;
	NSUInteger _extraPageKeyCount;
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

-(void) allocKeys:(NSMutableArray<NSString*>*)keysToAlloc page:(NSUInteger)page availableKeyCount:(NSUInteger)availableKeyCount {
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
}

//////////////////////////////////////////////////////////////////////
//Interface
//////////////////////////////////////////////////////////////////////
				 
-(id) init {
	self = [super init];
	if (self) {
		
		[self collectKeyboardKeys];
		
		_extraPageCount = 0;
		_extraPageKeyCount = 29; //Must be conforming with rowKeys layout!
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
			*outKeys    = @[@"Ex20", @"Ex21", @"Ex22", @"Ex23", @"Ex24", @"Ex25", @"Ex26", @"Ex27", @"Ex28", @"Ex29"];
			*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
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
		[self allocKeys:keysToAlloc page:page availableKeyCount:availableKeyCount];
	}];
	
	//Fill remaining not found keys on etxra pages
	NSUInteger remainingKeyCount = [keysToAlloc count];
	if (remainingKeyCount > 0) {
		_extraPageCount = remainingKeyCount / _extraPageKeyCount;
		if (remainingKeyCount % _extraPageKeyCount > 0) {
			++_extraPageCount;
		}
		
		for (NSUInteger page = 0; page < _extraPageCount; ++page) {
			[self allocKeys:keysToAlloc page:page + BASIC_PAGE_COUNT availableKeyCount:_extraPageKeyCount];
		}
	}
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

#pragma mark - Hungarian Keyboard

@implementation HunKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"Q", @"W", @"E", @"R", @"T", @"Z", @"U", @"I", @"O", @"P", BACKSPACE];
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
				*outKeys    = @[@"Á", @"É", @"Ó", @"Ö", @"Ő", @"Ú", @"Ü", @"Ű", @"Í", ENTER];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"Y", @"X", @"C", @"V", @"B", @"N", @"M"];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7"];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0];
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

#pragma mark - Japanese Katakana Keyboard

@implementation JapanKatakanaKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u30bf", @"\u30c6", @"\u30a4", @"\u30b9", @"\u30ab", @"\u30f3", @"\u30ca", @"\u30cb", @"\u30e9", @"\u30bb", @"\u30d8", @"\u30e0", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"\u30ed", @"\u30cc", @"\u30d5", @"\u30a2", @"\u30a6", @"\u30a8", @"\u30aa", @"\u30e4", @"\u30e6", @"\u30e8", @"\u30ef", @"\u30db", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u30c1", @"\u30c8", @"\u30b7", @"\u30cf", @"\u30ad", @"\u30af", @"\u30de", @"\u30ce", @"\u30ea", @"\u30ec", @"\u30b1", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,  @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", @"Ex11" ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,   @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u30c4", @"\u30b5", @"\u30bd", @"\u30d2", @"\u30b3", @"\u30df", @"\u30e2", @"\u30cd", @"\u30eb", @"\u30e1", @"\u309b", @"\u309c"];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17", @"Ex18", @"Ex19", @"Ex20", @"Ex21", @"Ex22", @"Ex23"];
				*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
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

#pragma mark - Japanese Hiragana Keyboard

@implementation JapanHiraganaKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u305f", @"\u3066", @"\u3044", @"\u3059", @"\u304b", @"\u3093", @"\u306a", @"\u306b", @"\u3089", @"\u305b", @"\u3080", @"\u3078", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"\u308d", @"\u306c", @"\u3075", @"\u3042", @"\u3046", @"\u3048", @"\u304a", @"\u3084", @"\u3086", @"\u3088", @"\u308f", @"\u307b", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u3061", @"\u3068", @"\u3057", @"\u306f", @"\u304d", @"\u304f", @"\u307e", @"\u306e", @"\u308a", @"\u308c", @"\u3051", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,  @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", @"Ex11" ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,   @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u3064", @"\u3055", @"\u305d", @"\u3072", @"\u3053", @"\u307f", @"\u3082", @"\u306d", @"\u308b", @"\u3081", @"\u309b", @"\u309c"];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17", @"Ex18", @"Ex19", @"Ex20", @"Ex21", @"Ex22", @"Ex23"];
				*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
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

#pragma mark - Chinese ChaJei Keyboard

//TODO: implement Chinese ChaJei Keyboard

#pragma mark - Chinese Bopomofo Keyboard

//TODO: implement Chinese Bopomofo Keyboard

#pragma mark - Russian Keyboard

//TODO: implement Russian Keyboard

#pragma mark - Arabic 102 Keyboard

//TODO: implement Arabic 102 Keyboard

#pragma mark - Persian Keyboard

//TODO: implement Persian Keyboard

#pragma mark - Thai Kedmanee Keyboard

//TODO: implement Thai Kedmanee Keyboard

#pragma mark - Thai Pattachote Keyboard

//TODO: implement Thai Pattachote Keyboard

#pragma mark - Greek Keyboard

//TODO: implement Greek Keyboard

@end
