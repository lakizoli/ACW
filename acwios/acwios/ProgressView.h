//
//  ProgressView.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 28..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressView : UIView

@property (nonatomic) IBInspectable float cornerRadius;
@property (nonatomic) IBInspectable float borderWidth;
@property (nonatomic) IBInspectable UIColor *borderColor;

@property (nonatomic) IBInspectable NSString *labelContent;
@property (nonatomic) IBInspectable NSString *buttonLabel;
@property (nonatomic) IBInspectable float progressValue;

@property (nonatomic) void (^onButtonPressed) (void);

@end
