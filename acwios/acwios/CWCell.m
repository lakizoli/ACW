//
//  CWCell.m
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "CWCell.h"
#import "SUIChooseCWViewController.h"

@implementation CWCell {
	UIColor *_disabledPackColor;
	UIColor *_disabledSelectedPackColor;
	UIColor *_normalTextColor;
	UIColor *_normalSubTextColor;
	UIColor *_selectionTextColor;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	
	// Initialization code
	_subscribed = NO;
	_disabledPackColor = [UIColor redColor];
	_disabledSelectedPackColor = [UIColor colorWithRed:1 green:0.3f blue:0.3f alpha:1];
	_normalTextColor = [UIColor colorWithRed:33.0f / 255.0f green:34.0f / 255.0f blue:33.0f / 255.0f alpha:1];
	_normalSubTextColor = [UIColor colorWithRed:78.0f / 255.0f green:80.0f / 255.0f blue:79.0f / 255.0f alpha:1];
	_selectionTextColor = [UIColor colorWithRed:223.0f / 255.0f green:194.0f / 255.0f blue:93.0f / 255.0f alpha:1];
	
	[self setSelectedBackgroundView:[[UIView alloc] init]];
	[[self selectedBackgroundView] setBackgroundColor:[UIColor colorWithRed:40.0f / 255.0f green:80.0f / 255.0f blue:80.0f / 255.0f alpha:1]];
	
	[self setMultipleSelectionBackgroundView:[[UIView alloc] init]];
	[[self multipleSelectionBackgroundView] setBackgroundColor:[UIColor colorWithRed:40.0f / 255.0f green:80.0f / 255.0f blue:80.0f / 255.0f alpha:1]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
	if (_subscribed) { //If program subscribed
		if (selected) {
			[[self packageName] setTextColor:_selectionTextColor];
			[[self statistics] setTextColor:_selectionTextColor];
			[[self openNextCW] setTintColor:_selectionTextColor];
			[[self chooseRandom] setTintColor:_selectionTextColor];
		} else {
			[[self packageName] setTextColor:_normalTextColor];
			[[self statistics] setTextColor:_normalSubTextColor];
			[[self openNextCW] setTintColor:_normalTextColor];
			[[self chooseRandom] setTintColor:_normalTextColor];
		}
	} else { //Non subscribed
		if (selected) {
			[[self packageName] setTextColor:_disabledSelectedPackColor];
			[[self statistics] setTextColor:_disabledSelectedPackColor];
			[[self openNextCW] setTintColor:_disabledSelectedPackColor];
			[[self chooseRandom] setTintColor:_disabledSelectedPackColor];
		} else {
			[[self packageName] setTextColor:_disabledPackColor];
			[[self statistics] setTextColor:_disabledPackColor];
			[[self openNextCW] setTintColor:_disabledPackColor];
			[[self chooseRandom] setTintColor:_disabledPackColor];
		}
	}
}

@end
