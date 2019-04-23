//
//  StoreViewController.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 10. 05..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubscriptionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface StoreViewController : UIViewController<SubscriptionManagerDelegate>


- (IBAction)buyMonthPressed:(id)sender;
- (IBAction)buyYearPressed:(id)sender;
- (IBAction)restoreButtonPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;

- (IBAction)considerationsTapped:(UITapGestureRecognizer *)sender;

@end

NS_ASSUME_NONNULL_END
