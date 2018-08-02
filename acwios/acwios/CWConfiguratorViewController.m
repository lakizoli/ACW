//
//  CWConfiguratorViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 08. 02..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CWConfiguratorViewController.h"
#import "ChoosePackageViewController.h"
#import "SubscriptionManager.h"
#import "PackageManager.h"

@interface CWConfiguratorViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *crosswordTable;

@end

@implementation CWConfiguratorViewController {
	BOOL _isSubscribed;
}

#pragma mark - Implementation

-(void) showSubscription {
	//TODO: implement subscribtion process in SubScriptionManager...
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subscribe" message:@"Let's take some subscription..." preferredStyle:UIAlertControllerStyleAlert];
	
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[[self subscribeView] setHidden:_isSubscribed];
	
	//TODO: load all before generated crossword...
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)subscribeButtonPressed:(id)sender {
	[self showSubscription];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

#pragma mark - Package Table

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
//		return [_packages count];
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CWCell" forIndexPath:indexPath];
	if (cell) {
//		Package* pack = [_packages objectAtIndex:indexPath.row];
//		if (pack) {
//			BOOL packEnabled = indexPath.row < 1 || _isSubscribed;
//			if (packEnabled) { //Enabled
//				[cell.textLabel setTextColor:[UIColor blackColor]];
//			} else { //Disabled
//				[cell.textLabel setTextColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
//			}
//
//			[cell.textLabel setText:[pack name]];
//
//			if (packEnabled) {
//				[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
//			} else {
//				[cell setAccessoryType:UITableViewCellAccessoryNone];
//			}
//		}
	}
	return cell;
}

@end
