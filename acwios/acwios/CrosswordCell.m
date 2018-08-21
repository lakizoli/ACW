//
//  CrosswordCell.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CrosswordCell.h"

@implementation CrosswordCell

-(void) setHiddensForFullHidden:(BOOL)fullHidden topHidden:(BOOL)topHidden bottomHidden:(BOOL)bottomHidden {
	[_fullLabel setHidden:fullHidden];
	[_topLabel setHidden:topHidden];
	[_bottomLabel setHidden:bottomHidden];
}

-(void) fillOneQuestion:(NSString*)question {
	[self setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
	[_fullLabel setText:question];
	[self setHiddensForFullHidden:NO topHidden:YES bottomHidden:YES];

	//TODO: ... make borders ...
}

-(void) fillTwoQuestion:(NSString*)questionTop questionBottom:(NSString*)questionBottom {
	[self setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
	[_topLabel setText:questionTop];
	[_bottomLabel setText:questionBottom];
	[self setHiddensForFullHidden:YES topHidden:NO bottomHidden:NO];
	
	//TODO: ... make borders ...
}

-(void) fillSpacer {
	[self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
}

-(void) fillLetter {
	[self setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
	
	//TODO: ... make borders ...
}

-(void) fillArrowWithQestionPos:(CGPoint)questionPos answerStart:(CGPoint)answerStart isVertical:(BOOL)isVertical {
	[self fillLetter];
	
	//TODO: ...
}

@end
