//
//  UITapGestureRecognizer+LinkInLabel.h
//  acwios
//
//  Created by Laki Zoltán on 2019. 04. 23..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITapGestureRecognizer (LinkInLabel)

-(BOOL) didTapAttributedTextInLabel:(UILabel*)label inRange:(NSRange)targetRange;

@end

NS_ASSUME_NONNULL_END
