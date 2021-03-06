//
//  CrosswordLayout.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CrosswordLayout : UICollectionViewLayout

@property (assign) CGFloat scaleFactor;
@property (assign) NSUInteger cellWidth;
@property (assign) NSUInteger cellHeight;
@property (assign) NSUInteger columnCount;
@property (assign) NSUInteger rowCount;
@property (assign) NSUInteger statusBarHeight;
@property (assign) NSUInteger navigationBarHeight;

@end
