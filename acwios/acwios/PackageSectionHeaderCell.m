//
//  PackageSectionHeaderCell.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 08. 23..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "PackageSectionHeaderCell.h"

@interface PackageSectionHeaderCell ()

@property (weak, nonatomic) IBOutlet UIButton *openCloseButton;
@property (weak, nonatomic) IBOutlet UIButton *selectDeselectAllButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation PackageSectionHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
	
	[self setBackgroundColor:[UIColor yellowColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setOpened {
	[_openCloseButton setImage:[UIImage imageNamed:@"collapse-arrow.png"] forState:UIControlStateNormal];
}

-(void)setClosed {
	[_openCloseButton setImage:[UIImage imageNamed:@"expand-arrow.png"] forState:UIControlStateNormal];
}

#pragma mark - Event handlers

- (IBAction)openCloseButtonPressed:(id)sender {
	if (_openCloseCallback) {
		_openCloseCallback ();
	}
}

- (IBAction)selectDeselectAllButtonPressed:(id)sender {
	if (_selectDeselectCallback) {
		_selectDeselectCallback ();
	}
}

- (IBAction)deleteButtonPressed:(id)sender {
	if (_deleteCallback) {
		_deleteCallback ();
	}
}

@end
