//
//  CWGeneratorViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 08. 03..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CWGeneratorViewController.h"
#import "PackageManager.h"

@interface CWGeneratorViewController ()

@end

@implementation CWGeneratorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
	//TODO: ... handle subscribe check for generation ...
	
	NSArray<Card*>* collectedCards = [[PackageManager sharedInstance] collectCardsOfPackage:_package];
	//TODO: ... load all cards available in package ...
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtorPressed:(id)sender {
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
