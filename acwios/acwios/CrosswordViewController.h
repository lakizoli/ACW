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

@property (strong) SavedCrossword *savedCrossword;

@end
