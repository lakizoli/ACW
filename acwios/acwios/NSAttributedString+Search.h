//
//  NSAttributedString+Search.h
//  acwios
//
//  Created by Laki Zoltán on 2019. 04. 23..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (Search)

- (NSRange) rangeOfFirstOccurence:(NSString*)search;

@end

NS_ASSUME_NONNULL_END
