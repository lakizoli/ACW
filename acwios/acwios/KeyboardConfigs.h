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

//All keyboard configuration have two pages (page1: normal characters, page2: numeric, and extra characters)
#define PAGE_ALPHA		0
#define PAGE_NUM		1

//Predefined extra keys on keyboard
#define BACKSPACE	@"BackSpace"
#define ENTER		@"Done"
#define SPACEBAR	@"Space"
#define TURNOFF		@"TurnOff"
#define SWITCHNUM	@"SwitchNum"
#define SWITCHALPHA	@"SwitchAlpha"

#pragma mark - KeyboardConfig

@protocol KeyboardConfig

@required
-(BOOL) rowKeys:(uint32_t)row page:(uint32_t)page outKeys:(NSArray<NSString*>**)outKeys outWieghts:(NSArray<NSNumber*>**)outWeights;

@end

#pragma mark - US Keyboard

@interface USKeyboard : NSObject<KeyboardConfig>

-(BOOL) rowKeys:(uint32_t)row page:(uint32_t)page outKeys:(NSArray<NSString*>**)outKeys outWieghts:(NSArray<NSNumber*>**)outWeights;

@end

//TODO: code all of supported international keyboards

#endif /* KeyboardConfigs_h */
