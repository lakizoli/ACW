//
//  GameTableCell.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 04..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "GameTableCell.h"

@implementation GameTableCell {
	UIColor *_disabledPackColor;
	UIColor *_disabledSelectedPackColor;
	UIColor *_selectionTextColor;
}

- (void)awakeFromNib {
    [super awakeFromNib];
	
    // Initialization code
	_subscribed = NO;
	_disabledPackColor = [UIColor redColor];
	_disabledSelectedPackColor = [UIColor colorWithRed:1 green:0.3f blue:0.3f alpha:1];
	_selectionTextColor = [UIColor colorWithRed:229.0f / 255.0f green:193.0f / 255.0f blue:71.0f / 255.0f alpha:1];
	
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
			[[self textLabel] setTextColor:_selectionTextColor];
		} else {
			[[self textLabel] setTextColor:nil];
		}
	} else { //Non subscribed
		if (selected) {
			[[self textLabel] setTextColor:_disabledSelectedPackColor];
		} else {
			[[self textLabel] setTextColor:_disabledPackColor];
		}
	}
}

@end
