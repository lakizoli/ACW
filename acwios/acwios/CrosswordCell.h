//
//  CrosswordCell.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Package.h"

@interface CrosswordCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *fullLabel;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;

-(void) fillOneQuestion:(NSString*)question scale:(CGFloat)scale;
-(void) fillTwoQuestion:(NSString*)questionTop questionBottom:(NSString*)questionBottom scale:(CGFloat)scale;

-(void) fillSpacer;
-(void) fillLetter:(BOOL)showValue value:(NSString*)value highlighted:(BOOL)highlighted currentCell:(BOOL)currentCell scale:(CGFloat)scale;
-(void) fillArrow:(enum CWCellType)cellType scale:(CGFloat)scale;
-(void) fillSeparator:(uint32_t)separators scale:(CGFloat)scale;

@end
