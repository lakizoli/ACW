//
//  SUIChooseCWViewController.h
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SUIChooseCWViewController : UIViewController<UITableViewDelegate>

- (IBAction)openNextCWPressed:(id)sender;
- (IBAction)choose:(id)sender;
- (IBAction)chooseRandomCW:(id)sender;
- (IBAction)deleteCW:(id)sender;

@end

NS_ASSUME_NONNULL_END
