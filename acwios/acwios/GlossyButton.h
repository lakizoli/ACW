//
//  GlossyButton.h
//  GlossyButton
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GlossyButton : UIButton

@property  (nonatomic) IBInspectable CGFloat hue;
@property  (nonatomic) IBInspectable CGFloat saturation;
@property  (nonatomic) IBInspectable CGFloat brightness;

@end
