//
//  KeyboardConfigs.h
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef KeyboardConfigs_h
#define KeyboardConfigs_h

#import <Foundation/Foundation.h>

//All keyboard configuration have minimum two pages (page1: normal characters, page2: numeric, and some extra characters)
//Altough arbitrary extra pages can be added after theese two page,
//if the count of extra characters is not enough to cover all characters used in the crossword!
#define PAGE_ALPHA			0
#define PAGE_NUM			1
#define BASIC_PAGE_COUNT	2

//Predefined extra keys on keyboard
#define BACKSPACE	@"BackSpace"
#define ENTER		@"Done"
#define SPACEBAR	@"Space"
#define TURNOFF		@"TurnOff"
#define SWITCH		@"Switch"

#pragma mark - KeyboardConfig

@interface KeyboardConfig : NSObject

-(id)init;

//This function have to be overriden in derived classes! The base function can be used only for extra pages!
-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

-(NSSet<NSString*>*) collectExtraKeys:(NSSet<NSString*>*)keysToCheck;
-(NSInteger) getExtraKeyID:(NSString*)key page:(NSUInteger)page;
-(NSString*) getValueForExtraKeyID:(NSInteger)extraKeyID;
-(NSString*) getTitleForExtraKeyID:(NSInteger)extraKeyID;

-(NSUInteger) getPageCount;
-(void) addExtraPages:(NSSet<NSString*>*)notFoundKeys;

@end

#pragma mark - US Keyboard

@interface USKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Hungarian Keyboard

@interface HunKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Japanese Katakana Keyboard

@interface JapanKatakanaKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Japanese Hiragana Keyboard

@interface JapanHiraganaKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Chinese ChaJei Keyboard

@interface ChineseChaJeiKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Chinese Bopomofo Keyboard

@interface ChineseBopomofoKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Russian Keyboard

@interface RussianKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Arabic 102 Keyboard

@interface Arabic102Keyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Persian Keyboard

@interface PersianKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Hindi Traditional Keyboard

@interface HindiTraditionalKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Thai Kedmanee Keyboard

@interface ThaiKedmaneeKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Thai Pattachote Keyboard

@interface ThaiPattachoteKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - Greek Keyboard

@interface GreekKeyboard : KeyboardConfig

-(BOOL) rowKeys:(NSUInteger)row page:(NSUInteger)page outKeys:(NSArray<NSString*>**)outKeys outWeights:(NSArray<NSNumber*>**)outWeights;

@end

#endif /* KeyboardConfigs_h */
