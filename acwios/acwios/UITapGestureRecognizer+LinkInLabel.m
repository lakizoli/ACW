//
//  UITapGestureRecognizer+LinkInLabel.m
//  acwios
//
//  Created by Laki Zoltán on 2019. 04. 23..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "UITapGestureRecognizer+LinkInLabel.h"

@implementation UITapGestureRecognizer (LinkInLabel)

-(BOOL) didTapAttributedTextInLabel:(UILabel*)label inRange:(NSRange)targetRange {
	NSLog (@"targetRange: %@", NSStringFromRange(targetRange));
	// Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:label.attributedText];
	
	// Configure layoutManager and textStorage
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	
	// Configure textContainer
	textContainer.lineFragmentPadding = 0.0;
	textContainer.lineBreakMode = label.lineBreakMode;
	textContainer.maximumNumberOfLines = label.numberOfLines;
	CGSize labelSize = label.frame.size;
	textContainer.size = labelSize;
	
	// Find the tapped character location and compare it to the specified range
	CGPoint locationOfTouchInLabel = [self locationInView:label];
	NSLog (@"locationOfTouchInLabel: %@", NSStringFromCGPoint(locationOfTouchInLabel));
	CGRect textBoundingBox = [layoutManager usedRectForTextContainer:textContainer];
	NSLog (@"textBoundingBox: %@", NSStringFromCGRect(textBoundingBox));
	CGPoint textContainerOffset = CGPointMake ((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
											   (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
	CGPoint locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
														 locationOfTouchInLabel.y - textContainerOffset.y);
	NSLog (@"locationOfTouchInTextContainer: %@", NSStringFromCGPoint(locationOfTouchInTextContainer));
	NSUInteger indexOfCharacter = [layoutManager characterIndexForPoint:locationOfTouchInTextContainer
														inTextContainer:textContainer
							   fractionOfDistanceBetweenInsertionPoints:nil];
	
	NSLog (@"%lu", indexOfCharacter);
	
	return NSLocationInRange (indexOfCharacter, targetRange);
}

@end
