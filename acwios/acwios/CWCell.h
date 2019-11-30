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
@property (weak, nonatomic) IBOutlet UIButton *randomButton;

- (void)localizeRandomButton;

@end

NS_ASSUME_NONNULL_END
