//
//  CrosswordViewController.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Package.h"

@interface CrosswordViewController : UICollectionViewController<UIKeyInput>

//Property for override system keyboard
@property (nonatomic, strong) UIInputViewController *inputViewController;

//Property of the choosen crossword
@property (strong) SavedCrossword *savedCrossword;

//Properties of the new game new workflow
@property (assign) BOOL isMultiLevelGame;
@property (assign) NSUInteger currentCrosswordIndex;

@end
