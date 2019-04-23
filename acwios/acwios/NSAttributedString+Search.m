//
//  NSAttributedString+Search.m
//  acwios
//
//  Created by Laki Zoltán on 2019. 04. 23..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "NSAttributedString+Search.h"

@implementation NSAttributedString (Search)

- (NSRange) rangeOfFirstOccurence:(NSString*)search {
	return [self.string rangeOfString:search];
}

@end
