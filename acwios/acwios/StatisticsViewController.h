//
//  StatisticsViewController.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 10. 04..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Charts/Charts.h>
#import "Package.h"

NS_ASSUME_NONNULL_BEGIN

@interface StatisticsViewController : UIViewController<IChartAxisValueFormatter>

//Property of the choosen crossword
@property (strong) SavedCrossword *savedCrossword;

@end

NS_ASSUME_NONNULL_END
