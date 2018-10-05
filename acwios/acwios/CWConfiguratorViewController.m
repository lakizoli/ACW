//
//  CWConfiguratorViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 08. 02..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CWConfiguratorViewController.h"
#import "ChoosePackageViewController.h"
#import "CWGeneratorViewController.h"
#import "SubscriptionManager.h"
#import "PackageManager.h"
#import "CrosswordViewController.h"
#import "GameTableCell.h"
#import "StatisticsViewController.h"

@interface CWConfiguratorViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *crosswordTable;
@property (weak, nonatomic) IBOutlet UINavigationItem *navItem;

@end

@implementation CWConfiguratorViewController {
	BOOL _isSubscribed;
	NSDictionary<NSString*, NSArray<SavedCrossword*>*> *_savedCrosswords;
	SavedCrossword *_selectedCrossword;
}

#pragma mark - Implementation

-(void) showSubscription {
	[[SubscriptionManager sharedInstance] showSubscriptionAlert:self
															msg:@"You have to subscribe to the application to play the disabled crosswords!"];
}

-(SavedCrossword*) savedCWFromIndexPath:(NSIndexPath*)indexPath {
	NSString *packageName = [[_savedCrosswords allKeys] objectAtIndex:indexPath.section];
	NSArray<SavedCrossword*> *cws = [_savedCrosswords objectForKey:packageName];
	return [cws objectAtIndex:indexPath.row];
}

-(void) deleteCrosswordAt:(NSIndexPath*)indexPath {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do You want to delete this crossword?"
																   message:@"You cannot undo this action."
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"Cancel"
													   style:UIAlertActionStyleCancel
													 handler:^(UIAlertAction * _Nonnull action)
		{
			//Nothing to do here...
		}];
	
	[alert addAction:actionNo];
	
	UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"Delete"
														style:UIAlertActionStyleDestructive
													  handler:^(UIAlertAction * _Nonnull action)
		{
			SavedCrossword *cw = [self savedCWFromIndexPath:indexPath];
			[cw eraseFromDisk];
			
			self->_savedCrosswords = [[PackageManager sharedInstance] collectSavedCrosswords];
			[self->_crosswordTable reloadData];
		}];
	
	[alert addAction:actionYes];
	
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[[self subscribeView] setHidden:_isSubscribed];
	
	if (_isStatisticsView) {
		_navItem.rightBarButtonItem = nil;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	_savedCrosswords = [[PackageManager sharedInstance] collectSavedCrosswords];
	[_crosswordTable reloadData];
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
	if ([identifier compare:@"ShowCrosswordView"] == NSOrderedSame ||
		[identifier compare:@"ShowStatisticsView"] == NSOrderedSame)
	{
		NSIndexPath *selectedRow = [_crosswordTable indexPathForSelectedRow];
		
		BOOL cwEnabled = ([selectedRow section] < 1 && [selectedRow row] < 1) || self->_isSubscribed;
		if (!cwEnabled) {
			[self showSubscription];
		} else {
			NSString* packageName = [[_savedCrosswords allKeys] objectAtIndex:[selectedRow section]];
			_selectedCrossword = [[_savedCrosswords objectForKey:packageName] objectAtIndex:[selectedRow row]];
			return YES;
		}
	} else if ([identifier compare:@"ShowPackageChooserView"] == NSOrderedSame) {
		return YES;
	}
	
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowCrosswordView"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[UINavigationController class]])
	{
		UINavigationController *navController = (UINavigationController*) [segue destinationViewController];
		if ([[navController topViewController] isKindOfClass:[CrosswordViewController class]]) {
			CrosswordViewController *cwController = (CrosswordViewController*) [navController topViewController];
			[cwController setSavedCrossword:_selectedCrossword];
		}
	} else if ([segue.identifier compare:@"ShowStatisticsView"] == NSOrderedSame &&
			   [segue.destinationViewController isKindOfClass:[StatisticsViewController class]])
	{
		StatisticsViewController *statViewController = (StatisticsViewController*) [segue destinationViewController];
		[statViewController setSavedCrossword:_selectedCrossword];
	}
}

#pragma mark - Package Table DataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [_savedCrosswords count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section >= 0 && section < [_savedCrosswords count]) {
		NSString *packageName = [[_savedCrosswords allKeys] objectAtIndex:section];
		return [NSString stringWithFormat:@"Package: %@", packageName];
	}
	
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section >= 0 && section < [_savedCrosswords count]) {
		NSString *packageName = [[_savedCrosswords allKeys] objectAtIndex:section];
		NSArray<SavedCrossword*> *cws = [_savedCrosswords objectForKey:packageName];
		return [cws count];
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	GameTableCell *cell = (GameTableCell*) [tableView dequeueReusableCellWithIdentifier:@"CWCell" forIndexPath:indexPath];
	if (cell && indexPath.section >= 0 && indexPath.section < [_savedCrosswords count]) {
		SavedCrossword *cw = [self savedCWFromIndexPath:indexPath];
		if (cw) {
			BOOL cwEnabled = (indexPath.section < 1 && indexPath.row < 1) || _isSubscribed;
			[cell setSubscribed:cwEnabled];

			NSString *label = [NSString stringWithFormat:@"[%dx%d] (%lu cards) - %@", [cw width], [cw height], [[cw words] count], [cw name]];
			[cell.textLabel setText:label];

			if (cwEnabled) {
				[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
			} else {
				[cell setAccessoryType:UITableViewCellAccessoryNone];
			}
		}
	}
	return cell;
}

#pragma mark - Package Table Editing

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @[ [UITableViewRowAction
			   rowActionWithStyle:UITableViewRowActionStyleDestructive
			   title:@"Delete crossword"
			   handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
				   [self deleteCrosswordAt:indexPath];
			   }]
			];
}

@end
