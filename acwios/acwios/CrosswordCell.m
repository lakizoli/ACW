//
//  CrosswordCell.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CrosswordCell.h"

@implementation CrosswordCell

#pragma mark - Implementation

-(void) setBorder:(UIView*)view {
	view.layer.borderColor = [[UIColor blackColor] CGColor];
	view.layer.borderWidth = 1.0f;
}

-(void) setHiddensForFullHidden:(BOOL)fullHidden topHidden:(BOOL)topHidden bottomHidden:(BOOL)bottomHidden {
	[_fullLabel setHidden:fullHidden];
	[_topLabel setHidden:topHidden];
	[_bottomLabel setHidden:bottomHidden];
}

-(void) clearContent {
	//Set all content to hidden
	[self setHiddensForFullHidden:YES topHidden:YES bottomHidden:YES];
	
	//Clear arrows and separators
	__block NSMutableArray<CALayer*> *sublayers = [NSMutableArray<CALayer*> new];
	[[[self layer] sublayers] enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (![obj isKindOfClass:[CAShapeLayer class]]) {
			[sublayers addObject:obj];
		}
	}];
	
	[[self layer] setSublayers:sublayers];
}

-(void) drawSeparatorLine:(CGPoint)ptStart ptEnd:(CGPoint)ptEnd {
	UIBezierPath *path = [UIBezierPath bezierPath];
	[path moveToPoint:ptStart];
	[path addLineToPoint:ptEnd];
	
	CAShapeLayer *shapeLayer = [CAShapeLayer layer];
	shapeLayer.path = [path CGPath];
	shapeLayer.strokeColor = [[UIColor blackColor] CGColor];
	shapeLayer.lineWidth = 2.0f;
	shapeLayer.fillColor = [[UIColor whiteColor] CGColor];
	
	[self.layer addSublayer:shapeLayer];
}

-(NSAttributedString*) attributedQuestionString:(NSString*)question scale:(CGFloat)scale {
	//Choose question's font
	CGFloat fontSize = [UIFont systemFontSize] * scale;
	UIFont* font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:fontSize];
	if (font == nil) {
		font = [UIFont fontWithName:@"Baskerville-Bold" size:fontSize];
	}
	if (font == nil) {
		font = [UIFont systemFontOfSize:fontSize];
	}
	
	return [[NSAttributedString alloc]
			initWithString:question
			attributes:@{ NSFontAttributeName: font }];
}

-(NSAttributedString*) attributedValueString:(NSString*)value scale:(CGFloat)scale {
	//Choose value font
	CGFloat fontSize = 26 * scale;
	UIFont* font = [UIFont fontWithName:@"BradleyHandITCTT-Bold" size:fontSize];
	if (font == nil) {
		font = [UIFont fontWithName:@"Baskerville-BoldItalic" size:fontSize];
	}
	if (font == nil) {
		font = [UIFont systemFontOfSize:fontSize];
	}
	
	//Make value capital
	NSString *content = [value uppercaseStringWithLocale:nil];

	return [[NSAttributedString alloc]
			initWithString:content
			attributes:@{ NSFontAttributeName: font }];
}

#pragma mark - Interface

-(void) fillOneQuestion:(NSString*)question scale:(CGFloat)scale {
	[self clearContent];
	[self setBorder:self];
	
	[self setBackgroundColor:[UIColor colorWithRed:214.0f / 255.0f green:222.0f / 255.0f blue:228.0f / 255.0f alpha:255.0f]];
	[_fullLabel setTextColor:[UIColor blackColor]];
	
	[_fullLabel setAttributedText:[self attributedQuestionString:question scale:scale]];
	[self setHiddensForFullHidden:NO topHidden:YES bottomHidden:YES];

	CGRect frame = [self frame];
	[_fullLabel setFrame:CGRectMake (0, 0, frame.size.width, frame.size.height)];
	[self setNeedsDisplay];
}

-(void) fillTwoQuestion:(NSString*)questionTop questionBottom:(NSString*)questionBottom scale:(CGFloat)scale {
	[self clearContent];
	[self setBorder:_topLabel];
	[self setBorder:_bottomLabel];
	
	[self setBackgroundColor:[UIColor colorWithRed:214.0f / 255.0f green:222.0f / 255.0f blue:228.0f / 255.0f alpha:255.0f]];

	[_topLabel setTextColor:[UIColor blackColor]];
	[_bottomLabel setTextColor:[UIColor blackColor]];

	[_topLabel setAttributedText:[self attributedQuestionString:questionTop scale:scale]];
	[_bottomLabel setAttributedText:[self attributedQuestionString:questionBottom scale:scale]];
	[self setHiddensForFullHidden:YES topHidden:NO bottomHidden:NO];

	CGRect frame = [self frame];
	[_topLabel setFrame:CGRectMake (0, 0, frame.size.width, frame.size.height / 2.0)];
	[_bottomLabel setFrame:CGRectMake (0, frame.size.height / 2.0, frame.size.width, frame.size.height / 2.0)];
	[self setNeedsDisplay];
}

-(void) fillSpacer {
	[self clearContent];
	[self setBorder:self];
	[self setBackgroundColor:[UIColor blackColor]];
}

-(void) fillLetter:(BOOL)showValue value:(NSString*)value highlighted:(BOOL)highlighted currentCell:(BOOL)currentCell scale:(CGFloat)scale {
	[self clearContent];
	[self setBorder:self];
	if (highlighted) {
		if (currentCell) {
			[self setBackgroundColor:[UIColor colorWithRed:56.0f / 255.0f green:112.0f / 255.0f blue:112.0f / 255.0f alpha:1]];
		} else {
			[self setBackgroundColor:[UIColor colorWithRed:40.0f / 255.0f green:80.0f / 255.0f blue:80.0f / 255.0f alpha:1]];
		}
		[_fullLabel setTextColor:[UIColor colorWithRed:229.0f / 255.0f green:193.0f / 255.0f blue:71.0f / 255.0f alpha:1]];
	} else {
		[self setBackgroundColor:[UIColor whiteColor]];
		[_fullLabel setTextColor:[UIColor blackColor]];
	}
	
	if (showValue) {
		[_fullLabel setAttributedText:[self attributedValueString:value scale:scale]];
		[self setHiddensForFullHidden:NO topHidden:YES bottomHidden:YES];
		
		CGRect frame = [self frame];
		[_fullLabel setFrame:CGRectMake (0, 0, frame.size.width, frame.size.height)];
		[self setNeedsDisplay];
	}
}

-(void) fillArrow:(enum CWCellType)cellType scale:(CGFloat)scale {
	const CGFloat baseX[] = { 0 * scale, 32 * scale, 25 * scale, 18 * scale };
	const CGFloat baseY[] = { 3 * scale,  3 * scale, 10 * scale,  3 * scale };
	
	UIBezierPath *path = nil;
	switch (cellType) {
		case CWCellType_Start_TopDown_Right:
			path = [UIBezierPath bezierPath];
			[path moveToPoint:CGPointMake (baseX[0], baseY[0])];
			[path addLineToPoint:CGPointMake (baseX[1], baseY[1])];
			[path addLineToPoint:CGPointMake (baseX[2], baseY[2])];
			[path addLineToPoint:CGPointMake (baseX[3], baseY[3])];
			break;
		case CWCellType_Start_TopDown_Left:
			path = [UIBezierPath bezierPath];
			[path moveToPoint:CGPointMake (50 - baseX[0], baseY[0])];
			[path addLineToPoint:CGPointMake (50 - baseX[1], baseY[1])];
			[path addLineToPoint:CGPointMake (50 - baseX[2], baseY[2])];
			[path addLineToPoint:CGPointMake (50 - baseX[3], baseY[3])];
			break;
		case CWCellType_Start_TopDown_Bottom:
			path = [UIBezierPath bezierPath];
			[path moveToPoint:CGPointMake (baseX[3], baseY[0])];
			[path addLineToPoint:CGPointMake (baseX[1], baseY[1])];
			[path addLineToPoint:CGPointMake (baseX[2], baseY[2])];
			[path addLineToPoint:CGPointMake (baseX[3], baseY[3])];
			break;
		case CWCellType_Start_TopRight:
			path = [UIBezierPath bezierPath];
			[path moveToPoint:CGPointMake (baseY[3], baseX[3] - 12.5f)];
			[path addLineToPoint:CGPointMake (baseY[1], baseX[1] - 12.5f)];
			[path addLineToPoint:CGPointMake (baseY[2], baseX[2] - 12.5f)];
			[path addLineToPoint:CGPointMake (baseY[3], baseX[3] - 12.5f)];
			break;
		case CWCellType_Start_FullRight:
			path = [UIBezierPath bezierPath];
			[path moveToPoint:CGPointMake (baseY[3], baseX[3])];
			[path addLineToPoint:CGPointMake (baseY[1], baseX[1])];
			[path addLineToPoint:CGPointMake (baseY[2], baseX[2])];
			[path addLineToPoint:CGPointMake (baseY[3], baseX[3])];
			break;
		case CWCellType_Start_BottomRight:
			path = [UIBezierPath bezierPath];
			[path moveToPoint:CGPointMake (baseY[3], baseX[3] + 12.5f)];
			[path addLineToPoint:CGPointMake (baseY[1], baseX[1] + 12.5f)];
			[path addLineToPoint:CGPointMake (baseY[2], baseX[2] + 12.5f)];
			[path addLineToPoint:CGPointMake (baseY[3], baseX[3] + 12.5f)];
			break;
		case CWCellType_Start_LeftRight_Top:
			path = [UIBezierPath bezierPath];
			[path moveToPoint:CGPointMake (baseY[0], 50 - baseX[0])];
			[path addLineToPoint:CGPointMake (baseY[1], 50 - baseX[1])];
			[path addLineToPoint:CGPointMake (baseY[2], 50 - baseX[2])];
			[path addLineToPoint:CGPointMake (baseY[3], 50 - baseX[3])];
			break;
		case CWCellType_Start_LeftRight_Bottom:
			path = [UIBezierPath bezierPath];
			[path moveToPoint:CGPointMake (baseY[0], baseX[0])];
			[path addLineToPoint:CGPointMake (baseY[1], baseX[1])];
			[path addLineToPoint:CGPointMake (baseY[2], baseX[2])];
			[path addLineToPoint:CGPointMake (baseY[3], baseX[3])];
			break;
		default:
			break;
	}
	
	if (path) {
		CAShapeLayer *shapeLayer = [CAShapeLayer layer];
		shapeLayer.path = [path CGPath];
		shapeLayer.strokeColor = [[UIColor blackColor] CGColor];
		shapeLayer.lineWidth = 2.0f;
		shapeLayer.fillColor = [[UIColor whiteColor] CGColor];
		
		[self.layer addSublayer:shapeLayer];
	}
}

-(void) fillSeparator:(uint32_t)separators scale:(CGFloat)scale {
	const CGFloat coords[] = { 1 * scale, 49 * scale };
	
	if ((separators & CWCellSeparator_Left) == CWCellSeparator_Left) {
		[self drawSeparatorLine:CGPointMake (coords[0], coords[1])
						  ptEnd:CGPointMake (coords[0], coords[0])];
	}
	
	if ((separators & CWCellSeparator_Top) == CWCellSeparator_Top) {
		[self drawSeparatorLine:CGPointMake (coords[0], coords[0])
						  ptEnd:CGPointMake (coords[1], coords[0])];
	}
	
	if ((separators & CWCellSeparator_Right) == CWCellSeparator_Right) {
		[self drawSeparatorLine:CGPointMake (coords[1], coords[0])
						  ptEnd:CGPointMake (coords[1], coords[1])];
	}
	
	if ((separators & CWCellSeparator_Bottom) == CWCellSeparator_Bottom) {
		[self drawSeparatorLine:CGPointMake (coords[0], coords[1])
						  ptEnd:CGPointMake (coords[1], coords[1])];
	}
}

@end
