//
//  SUIChooseLevelViewController.m
//  acwios
//
//  Created by Zoli on 2022. 10. 20..
//  Copyright © 2022. ZApp. All rights reserved.
//

#import "SUIChooseLevelViewController.h"

@interface SUIChooseLevelViewController ()

@end

@implementation SUIChooseLevelViewController

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
