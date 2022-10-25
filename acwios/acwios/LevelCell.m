//
//  LevelCell.m
//  acwios
//
//  Created by Zoli on 2022. 10. 20..
//  Copyright © 2022. ZApp. All rights reserved.
//

#import "LevelCell.h"

@implementation LevelCell {
	UIColor *_disabledPackColor;
	UIColor *_disabledSelectedPackColor;
	UIColor *_normalTextColor;
	UIColor *_selectionTextColor;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	
	_disabledPackColor = [UIColor redColor];
	_disabledSelectedPackColor = [UIColor colorWithRed:1 green:0.3f blue:0.3f alpha:1];
	_normalTextColor = [UIColor colorWithRed:33.0f / 255.0f green:34.0f / 255.0f blue:33.0f / 255.0f alpha:1];
	_selectionTextColor = [UIColor colorWithRed:223.0f / 255.0f green:194.0f / 255.0f blue:93.0f / 255.0f alpha:1];
}

-(void)setState:(NSInteger)idx lastPlayedLevel:(NSUInteger)lastPlayedLevel isSubscribed:(BOOL)isSubscribed {
	if (isSubscribed) {
		[_textView setTextColor:_normalTextColor];

		[_lockImage setTintColor:_normalTextColor];
		[_lockImage setHidden:idx <= lastPlayedLevel];
	} else {
		[_textView setTextColor:idx <= 0 ? _normalTextColor : _disabledPackColor];
		
		[_lockImage setTintColor:_disabledPackColor];
		[_lockImage setHidden:idx <= 0];
	}
}

-(BOOL)isLocked {
	return ![_lockImage isHidden];
}

@end
