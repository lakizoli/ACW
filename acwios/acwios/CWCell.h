//
//  CWCell.h
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SUIChooseCWViewController;

NS_ASSUME_NONNULL_BEGIN

@interface CWCell : UITableViewCell

@property (nonatomic, assign) BOOL subscribed;
@property (nonatomic, weak) SUIChooseCWViewController* parent;
@property (nonatomic, strong) NSString* packageKey;

@property (weak, nonatomic) IBOutlet UILabel *packageName;
@property (weak, nonatomic) IBOutlet UILabel *statistics;
@property (weak, nonatomic) IBOutlet UIImageView *openNextCW;
@property (weak, nonatomic) IBOutlet UIImageView *choose;
@property (weak, nonatomic) IBOutlet UIImageView *chooseRandom;
@property (weak, nonatomic) IBOutlet UIImageView *deleteCW;

@end

NS_ASSUME_NONNULL_END
