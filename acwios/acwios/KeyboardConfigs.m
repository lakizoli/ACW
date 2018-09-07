//
//  KeyboardConfigs.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 07..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "KeyboardConfigs.h"

#pragma mark - US Keyboard

@implementation USKeyboard

-(BOOL) rowKeys:(uint32_t)row page:(uint32_t)page outKeys:(NSArray<NSString*>**)outKeys outWieghts:(NSArray<NSNumber*>**)outWeights {
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
			if (page == PAGE_ALPHA) {
				*outKeys    = @[SWITCHNUM, SPACEBAR, TURNOFF];
				*outWeights = @[     @1.0,     @3.0,    @1.0];
				return YES;
			} else if (page == PAGE_NUM) {
				*outKeys    = @[SWITCHALPHA, SPACEBAR, TURNOFF];
				*outWeights = @[       @1.0,     @3.0,    @1.0];
				return YES;
			}
			break;
		default:
			break;
	}
	
	return NO;
}

@end
