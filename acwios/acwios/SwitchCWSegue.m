//
//  SwitchCWSegue.m
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "SwitchCWSegue.h"

@implementation SwitchCWSegue

- (void)perform {
	UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
	UINavigationController *navigationController = sourceViewController.navigationController;
	
	__block UIViewController *parentViewController = [navigationController presentingViewController];
	[navigationController dismissViewControllerAnimated:YES completion:^{
		UIViewController *destinationController = (UIViewController*)[self destinationViewController];
		[parentViewController presentViewController:destinationController animated:YES completion:nil];
	}];
}

@end
