//
//  CWConfiguratorViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 08. 02..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CWConfiguratorViewController.h"
#import "ChoosePackageViewController.h"

@interface CWConfiguratorViewController ()

@end

@implementation CWConfiguratorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
