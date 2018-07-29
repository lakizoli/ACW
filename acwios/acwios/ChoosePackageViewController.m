//
//  ChoosePackageViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "ChoosePackageViewController.h"
#import "SubscriptionManager.h"
#import "PackageManager.h"

@interface ChoosePackageViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *packageTable;

@end

@implementation ChoosePackageViewController {
	BOOL _isSubscribed;
	NSArray<Package*>* _packages;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[[self subscribeView] setHidden:_isSubscribed];
	
	NSArray<Package*>* collectedPackages = [[PackageManager sharedInstance] collectPackages];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
																   ascending:YES
																	selector:@selector (localizedStandardCompare:)];
	
	_packages = [collectedPackages sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)subscribeButtonPressed:(id)sender {
	//TODO: implement subscribtion process in SubScriptionManager...
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subscribe" message:@"Let's take some subscription..." preferredStyle:UIAlertControllerStyleAlert];
	
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Package Table

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return 1;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PackageCell" forIndexPath:indexPath];
	if (cell) {
		[cell.textLabel setTextColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		[cell.textLabel setText:@"juhu red"];
		[cell setAccessoryType:UITableViewCellAccessoryNone];
	}
	return cell;
}

@end
