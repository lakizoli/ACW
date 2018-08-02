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
#import "CWConfiguratorViewController.h"

@interface ChoosePackageViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *packageTable;

@end

@implementation ChoosePackageViewController {
	BOOL _isSubscribed;
	NSArray<Package*>* _packages;
	Package *_choosenPackage;
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
	[self showSubscription];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([sender isKindOfClass:[UITableViewCell class]]) {
		UITableViewCell* cell = (UITableViewCell*)sender;
		NSIndexPath* indexPath = [_packageTable indexPathForCell:cell];
		BOOL packEnabled = indexPath.row < 1 || _isSubscribed;
		if (packEnabled) {
			_choosenPackage = [_packages objectAtIndex:indexPath.row];
			return YES;
		} else { //Choose a not allowed package
			[self showSubscription];
		}
	}
	
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.destinationViewController isKindOfClass:[CWConfiguratorViewController class]] && _choosenPackage) {
		CWConfiguratorViewController *configView = (CWConfiguratorViewController*) segue.destinationViewController;
		configView.package = _choosenPackage;
	}
}

#pragma mark - Package Table

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return [_packages count];
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PackageCell" forIndexPath:indexPath];
	if (cell) {
		Package* pack = [_packages objectAtIndex:indexPath.row];
		if (pack) {
			BOOL packEnabled = indexPath.row < 1 || _isSubscribed;
			if (packEnabled) { //Enabled
				[cell.textLabel setTextColor:[UIColor blackColor]];
			} else { //Disabled
				[cell.textLabel setTextColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
			}
			
			[cell.textLabel setText:[pack name]];
			
			if (packEnabled) {
				[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
			} else {
				[cell setAccessoryType:UITableViewCellAccessoryNone];
			}
		}
	}
	return cell;
}

@end
