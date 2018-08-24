//
//  PackageSectionHeaderCell.h
//  acwios
//
//  Created by Laki, Zoltan on 2018. 08. 23..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PackageSectionHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong) void (^openCloseCallback)(void);
@property (strong) void (^selectDeselectCallback)(void);
@property (strong) void (^deleteCallback)(void);

-(void)setOpened;
-(void)setClosed;

-(void)setSelectAll;
-(void)setDeselectAll;

@end
