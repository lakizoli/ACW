//
//  LevelCell.h
//  acwios
//
//  Created by Zoli on 2022. 10. 20..
//  Copyright © 2022. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LevelCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *lockImage;

-(void)setState:(NSInteger)idx lastPlayedLevel:(NSUInteger)lastPlayedLevel isSubscribed:(BOOL)isSubscribed;
-(BOOL)isLocked;

@end

NS_ASSUME_NONNULL_END
