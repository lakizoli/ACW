//
//  CrosswordCell.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CrosswordCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *fullLabel;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;

-(void) fillOneQuestion:(NSString*)question;
-(void) fillTwoQuestion:(NSString*)questionTop questionBottom:(NSString*)questionBottom;

-(void) fillSpacer;
-(void) fillLetter;
-(void) fillArrowWithQestionPos:(CGPoint)questionPos answerStart:(CGPoint)answerStart isVertical:(BOOL)isVertical;

@end
