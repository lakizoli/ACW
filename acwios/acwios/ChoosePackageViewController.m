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
	Deck *_choosenDeck;
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
	if ([identifier compare:@"ShowConfiguratorView"] == NSOrderedSame && [sender isKindOfClass:[UITableViewCell class]]) {
		UITableViewCell* cell = (UITableViewCell*) sender;
		NSIndexPath* indexPath = [_packageTable indexPathForCell:cell];
		BOOL packEnabled = (indexPath.section < 1 && indexPath.row < 1) || _isSubscribed;
		if (packEnabled) {
			if (indexPath.section >= 0 && indexPath.section < [_packages count]) {
				Package* choosenPackage = [_packages objectAtIndex:indexPath.section];
				NSArray<Deck*> *decks = [choosenPackage decks];
				if (indexPath.row >= 0 && indexPath.row < [decks count]) {
					_choosenDeck = [decks objectAtIndex:indexPath.row];
					return YES;
				}
			}
		} else { //Choose a not allowed package
			[self showSubscription];
		}
	}
	
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowConfiguratorView"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[CWConfiguratorViewController class]] &&
		_choosenDeck)
	{
		CWConfiguratorViewController *configView = (CWConfiguratorViewController*) segue.destinationViewController;
		[configView setDeck: _choosenDeck];
	}
}

#pragma mark - Package Table

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [_packages count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section >= 0 && section < [_packages count]) {
		Package* package = [_packages objectAtIndex:section];
		return [NSString stringWithFormat:@"Package: %@", [package name]];
	}
	
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section >= 0 && section < [_packages count]) {
		Package* package = [_packages objectAtIndex:section];
		return [[package decks] count];
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PackageCell" forIndexPath:indexPath];
	if (cell && indexPath.section >= 0 && indexPath.section < [_packages count]) {
		Package* pack = [_packages objectAtIndex:indexPath.section];
		
		BOOL packEnabled = (indexPath.section < 1 && indexPath.row < 1) || _isSubscribed;
		if (packEnabled) { //Enabled
			[cell.textLabel setTextColor:[UIColor blackColor]];
		} else { //Disabled
			[cell.textLabel setTextColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		}
		
		NSArray<Deck*> *decks = [pack decks];
		if (indexPath.row >= 0 && indexPath.row < [decks count]) {
			Deck *deck = [decks objectAtIndex:indexPath.row];
			[cell.textLabel setText:[deck name]];
			
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
