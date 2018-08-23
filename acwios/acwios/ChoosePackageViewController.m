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
#import "CWGeneratorViewController.h"
#import "PackageSectionHeaderCell.h"

@interface ChoosePackageViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *configureButton;
@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *packageTable;

@end

@implementation ChoosePackageViewController {
	BOOL _isSubscribed;
	NSArray<Package*>* _packages;
	NSArray<Deck*> *_choosenDecks;
}

#pragma mark - Implementation

-(void) showSubscription {
	//TODO: implement subscribtion process in SubScriptionManager...
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subscribe" message:@"Let's take some subscription..." preferredStyle:UIAlertControllerStyleAlert];
	
	[self presentViewController:alert animated:YES completion:nil];
}

-(void) reloadPackages {
	NSArray<Package*>* collectedPackages = [[PackageManager sharedInstance] collectPackages];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
																   ascending:YES
																	selector:@selector (localizedStandardCompare:)];
	
	_packages = [collectedPackages sortedArrayUsingDescriptors:@[sortDescriptor]];
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[_subscribeView setHidden:_isSubscribed];
	
	[_configureButton setEnabled:NO];

	[self reloadPackages];
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
	if ([identifier compare:@"ShowGenerateView"] == NSOrderedSame && [sender isKindOfClass:[UIBarButtonItem class]]) {
		NSArray<NSIndexPath*> *selectedRows = [_packageTable indexPathsForSelectedRows];

		__block BOOL showSubscriptionAlert = NO;
		__block NSMutableArray<Deck*> *selectedDecks = [NSMutableArray<Deck*> new];
		[selectedRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
			BOOL packEnabled = (indexPath.section < 1 && indexPath.row < 1) || self->_isSubscribed;
			if (!packEnabled) {
				showSubscriptionAlert = YES;
				*stop = YES;
			}
			
			Package *choosenPackage = [self->_packages objectAtIndex:indexPath.section];
			NSArray<Deck*> *decks = [choosenPackage decks];
			if (indexPath.row >= 0 && indexPath.row < [decks count]) {
				[selectedDecks addObject:[decks objectAtIndex:indexPath.row]];
			}
		}];
		
		if (showSubscriptionAlert) {
			[self showSubscription];
		} else if ([selectedDecks count] <= 0) {
			//... Cannot happen because of disabling configure button
			return NO;
		} else { //We have a valid deck set
			self->_choosenDecks = selectedDecks;
			return YES;
		}
	}
	
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowGenerateView"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[CWGeneratorViewController class]] &&
		[_choosenDecks count] > 0)
	{
		CWGeneratorViewController *genView = (CWGeneratorViewController*) segue.destinationViewController;
		[genView setDecks: _choosenDecks];
	}
}

#pragma mark - Package Table

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [_packages count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	__block PackageSectionHeaderCell *sectionHeaderCell = [tableView dequeueReusableCellWithIdentifier:@"PackageSectionHeaderCell"];
	if (sectionHeaderCell) {
		if (section >= 0 && section < [_packages count]) {
			__block Package* package = [_packages objectAtIndex:section];
			[[sectionHeaderCell titleLabel] setText:[NSString stringWithFormat:@"Package: %@", [package name]]];
			[sectionHeaderCell setOpenCloseCallback:^{
				//TODO: handle open close
				NSLog (@"open/close called! section: %li", section);
			}];
			[sectionHeaderCell setSelectDeselectCallback:^{
				//TODO: handle select deselect
				NSLog (@"select/deselect called! section: %li", section);
			}];
			[sectionHeaderCell setDeleteCallback:^{
				NSError *err = nil;
				if ([[NSFileManager defaultManager] removeItemAtURL:[package path] error:&err] != YES) {
					NSLog (@"Cannot remove package at path: %@, error: %@", [package path], err);
				}
				
				[self reloadPackages];
				[self->_packageTable reloadData];
			}];
		} else {
			[[sectionHeaderCell titleLabel] setText:@""];
			[sectionHeaderCell setOpenCloseCallback:nil];
			[sectionHeaderCell setSelectDeselectCallback:nil];
			[sectionHeaderCell setDeleteCallback:nil];
		}
	}
	return sectionHeaderCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 43;
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
		}
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray<NSIndexPath*> *selectedRows = [tableView indexPathsForSelectedRows];
	if ([selectedRows count] <= 0) {
		[_configureButton setEnabled:NO];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray<NSIndexPath*> *selectedRows = [tableView indexPathsForSelectedRows];
	
	if ([selectedRows count] > 0) {
		[_configureButton setEnabled:YES];
	}
	
	[selectedRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (indexPath.section != obj.section) {
			[tableView deselectRowAtIndexPath:obj animated:YES];
		}
	}];
}

@end
