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

@end

#pragma mark - Chinese ChaJei Keyboard

@implementation ChineseChaJeiKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u624b", @"\u7530", @"\u6c34", @"\u53e3", @"\u5eff", @"\u535c", @"\u5c71", @"\u6208", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", BACKSPACE];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u65e5", @"\u5c38", @"\u6728", @"\u706b", @"\u571f", @"\u7af9", @"\u5341", @"\u5927", @"\u4e2d", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,   @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\uff3a", @"\u96e3", @"\u91d1", @"\u5973", @"\u6708", @"\u5f13", @"\u4e00", @"\u4eba", @"\u5fc3"];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex10", @"Ex11", @"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17", @"Ex18"];
				*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
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


#pragma mark - Chinese Bopomofo Keyboard

@implementation ChineseBopomofoKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u3106", @"\u310a", @"\u310d", @"\u3110", @"\u3114", @"\u3117", @"\u3127", @"\u311b", @"\u311f", @"\u3123", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"\u3105", @"\u3109", @"\u02c7", @"\u02cb", @"\u3113", @"\u02ca", @"\u02d9", @"\u311a", @"\u311e", @"\u3122", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u3107", @"\u310b", @"\u310e", @"\u3111", @"\u3115", @"\u3118", @"\u3128", @"\u311c", @"\u3120", @"\u3124", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,   @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u3108", @"\u310c", @"\u310f", @"\u3112", @"\u3116", @"\u3119", @"\u3129", @"\u311d", @"\u3121", @"\u3125", @"\u3126"];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex11", @"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17", @"Ex18", @"Ex19", @"Ex20", @"Ex21"];
				*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
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


#pragma mark - Russian Keyboard

@implementation RussianKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[[@"\u0439" uppercaseString], [@"\u0446" uppercaseString], [@"\u0443" uppercaseString], [@"\u043a" uppercaseString],
								[@"\u0435" uppercaseString], [@"\u043d" uppercaseString], [@"\u0433" uppercaseString], [@"\u0448" uppercaseString],
								[@"\u0449" uppercaseString], [@"\u0437" uppercaseString], [@"\u0445" uppercaseString], BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", BACKSPACE];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[[@"\u0444" uppercaseString], [@"\u044b" uppercaseString], [@"\u0432" uppercaseString], [@"\u0430" uppercaseString],
								[@"\u043f" uppercaseString], [@"\u0440" uppercaseString], [@"\u043e" uppercaseString], [@"\u043b" uppercaseString],
								[@"\u0434" uppercaseString], [@"\u0436" uppercaseString], [@"\u044d" uppercaseString], ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,     @1.0,   @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", @"Ex11", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,    @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[[@"\u044f" uppercaseString], [@"\u0447" uppercaseString], [@"\u0441" uppercaseString], [@"\u043c" uppercaseString],
								[@"\u0438" uppercaseString], [@"\u0442" uppercaseString], [@"\u044c" uppercaseString], [@"\u0431" uppercaseString],
								[@"\u044e" uppercaseString], [@"\u0451" uppercaseString], [@"\u044a" uppercaseString]];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17", @"Ex18", @"Ex19", @"Ex20", @"Ex21", @"Ex22"];
				*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
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

#pragma mark - Arabic 102 Keyboard

@implementation Arabic102Keyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0636", @"\u0635", @"\u062b", @"\u0642", @"\u0641", @"\u063a", @"\u0639", @"\u0647", @"\u062e", @"\u062d", @"\u062c", @"\u062f", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", BACKSPACE];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0634", @"\u0633", @"\u064a", @"\u0628", @"\u0644", @"\u0627", @"\u062a", @"\u0646", @"\u0645", @"\u0643", @"\u0637", @"\u0630", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,     @1.0,       @1.0,  @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", @"Ex11", @"Ex12", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,    @1.0,    @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0640", @"\u0626", @"\u0621", @"\u0624", @"\u0631", @"\u0644", @"\u0627", @"\u0649", @"\u0629", @"\u0648", @"\u0632", @"\u0638"];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17", @"Ex18", @"Ex19", @"Ex20", @"Ex21", @"Ex22", @"Ex23", @"Ex24"];
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

#pragma mark - Persian Keyboard

@implementation PersianKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0636", @"\u0635", @"\u062b", @"\u0642", @"\u0641", @"\u063a", @"\u0639", @"\u0647", @"\u062e", @"\u062d", @"\u062c", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", BACKSPACE];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0634", @"\u0633", @"\u06cc", @"\u0628", @"\u0644", @"\u0627", @"\u062a", @"\u0646", @"\u0645", @"\u06a9", @"\u06af", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,  @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", @"Ex11", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,    @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u067e", @"\u0638", @"\u0637", @"\u0632", @"\u0631", @"\u0630", @"\u062f", @"\u0626", @"\u0648", @"\u0686", @"\u067e"];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17", @"Ex18", @"Ex19", @"Ex20", @"Ex21", @"Ex22"];
				*outWeights = @[   @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0,    @1.0];
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


#pragma mark - Thai Kedmanee Keyboard

@implementation ThaiKedmaneeKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0e46", @"\u0e44", @"\u0e33", @"\u0e1e", @"\u0e30", @"\u0e31", @"\u0e35", @"\u0e23", @"\u0e19", @"\u0e22", @"\u0e1a", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"\u0e45", @"\u0e20", @"\u0e16", @"\u0e38", @"\u0e36", @"\u0e04", @"\u0e15", @"\u0e08", @"\u0e02", @"\u0e0a", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0e1f", @"\u0e2b", @"\u0e01", @"\u0e14", @"\u0e40", @"\u0e49", @"\u0e48", @"\u0e32", @"\u0e2a", @"\u0e27", @"\u0e07", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,  @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", @"Ex11", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,    @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0e1c", @"\u0e1b", @"\u0e41", @"\u0e2d", @"\u0e34", @"\u0e37", @"\u0e17", @"\u0e21", @"\u0e43", @"\u0e1d", @"\u0e25", @"\u0e03"];
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


#pragma mark - Thai Pattachote Keyboard

@implementation ThaiPattachoteKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0e47", @"\u0e15", @"\u0e22", @"\u0e2d", @"\u0e23", @"\u0e48", @"\u0e14", @"\u0e21", @"\u0e27", @"\u0e41", @"\u0e43", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"\u0e52", @"\u0e53", @"\u0e54", @"\u0e55", @"\u0e39", @"\u0e57", @"\u0e58", @"\u0e59", @"\u0e50", @"\u0e51", @"\u0e56", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0e49", @"\u0e17", @"\u0e07", @"\u0e01", @"\u0e31", @"\u0e35", @"\u0e32", @"\u0e19", @"\u0e40", @"\u0e44", @"\u0e02", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,  @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", @"Ex11", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,    @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u0e1a", @"\u0e1b", @"\u0e25", @"\u0e2b", @"\u0e34", @"\u0e04", @"\u0e2a", @"\u0e30", @"\u0e08", @"\u0e1e", @"\u0e0c", @"\uf8c7"];
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

#pragma mark - Greek Keyboard

@implementation GreekKeyboard

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights {
	if (page >= BASIC_PAGE_COUNT) {
		return [super rowKeys:row page:page outKeys:outKeys outWeights:outWeights];
	}
	
	switch (row) {
		case 0:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u03c2", @"\u03b5", @"\u03c1", @"\u03c4", @"\u03c5", @"\u03b8", @"\u03b9", @"\u03bf", @"\u03c0", BACKSPACE];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", BACKSPACE];
				*outWeights = @[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,      @2.0];
				return YES;
			}
			break;
		case 1:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u03b1", @"\u03c3", @"\u03b4", @"\u03c6", @"\u03b3", @"\u03b7", @"\u03be", @"\u03ba", @"\u03bb", @"\u0384", ENTER];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,  @2.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex1", @"Ex2", @"Ex3", @"Ex4", @"Ex5", @"Ex6", @"Ex7", @"Ex8", @"Ex9", @"Ex10", ENTER];
				*outWeights = @[  @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,   @1.0,    @1.0,  @2.0];
				return YES;
			}
			break;
		case 2:
			if (page == PAGE_ALPHA) {
				*outKeys    = @[@"\u03b6", @"\u03c7", @"\u03c8", @"\u03c9", @"\u03b2", @"\u03bd", @"\u03bc"];
				*outWeights = @[     @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0,      @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[@"Ex11", @"Ex12", @"Ex13", @"Ex14", @"Ex15", @"Ex16", @"Ex17"];
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
