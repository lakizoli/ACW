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

-(void) fillOneQuestion:(NSString*)question;
-(void) fillTwoQuestion:(NSString*)questionTop questionBottom:(NSString*)questionBottom;

-(void) fillSpacer;
-(void) fillLetter:(BOOL)showValue value:(NSString*)value;
-(void) fillArrow:(enum CWCellType)cellType;
-(void) fillSeparator:(uint32_t)separators;

@end
