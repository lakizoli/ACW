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
@property (weak, nonatomic) IBOutlet UIView *helpOfPlusButton;
@property (weak, nonatomic) IBOutlet UIView *helpOfBackButton;

@end

@implementation CWConfiguratorViewController {
	BOOL _isSubscribed;
	NSDictionary<NSString*, NSArray<SavedCrossword*>*> *_savedCrosswords;
	SavedCrossword *_selectedCrossword;
}

#pragma mark - Implementation

-(void) showSubscription {
	[[SubscriptionManager sharedInstance] showSubscriptionAlert:self
															msg:@"You have to subscribe to the application to play the disabled crosswords! If you press yes, then we take you to our store screen to do that."];
}

-(SavedCrossword*) savedCWFromIndexPath:(NSIndexPath*)indexPath {
	NSString *packageName = [[_savedCrosswords allKeys] objectAtIndex:indexPath.section];
	NSArray<SavedCrossword*> *cws = [_savedCrosswords objectForKey:packageName];
	return [cws objectAtIndex:indexPath.row];
}

-(void) deleteCrosswordAt:(NSIndexPath*)indexPath {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do you want to delete this crossword?"
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
	if (_isStatisticsView) {
		_navItem.rightBarButtonItem = nil;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[[self subscribeView] setHidden:_isSubscribed];

	PackageManager *man = [PackageManager sharedInstance];
	BOOL hasSomePackages = [[man collectPackages] count] > 0;
	
	_savedCrosswords = [man collectSavedCrosswords];
	__block BOOL hasSomeCrossword = NO;
	if (hasSomePackages) {
		[_savedCrosswords enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<SavedCrossword *> * _Nonnull obj, BOOL * _Nonnull stop) {
			if ([obj count] > 0) {
				hasSomeCrossword = YES;
				*stop = YES;
			}
		}];
	}

	if(_isStatisticsView) {
		[_helpOfBackButton setHidden:hasSomeCrossword];
		[_navItem.rightBarButtonItem setEnabled:NO];
		[_helpOfPlusButton setHidden:YES];
	} else {
		[_helpOfBackButton setHidden:hasSomePackages];
		[_navItem.rightBarButtonItem setEnabled:hasSomePackages];
		[_helpOfPlusButton setHidden:!hasSomePackages || hasSomeCrossword];
	}
	
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
	[[SubscriptionManager sharedInstance] showStore:self];
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
		
		NSArray<SavedCrossword*> *cws = [_savedCrosswords objectForKey:packageName];
		__block NSUInteger sumWordCount = 0;
		__block NSUInteger sumFilledWordCount = 0;
		[cws enumerateObjectsUsingBlock:^(SavedCrossword * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			sumWordCount += [[obj words] count];
			
			NSArray<Statistics*> *stats = [obj loadStatistics];
			if ([stats count] > 1) {
				sumFilledWordCount += [[obj words] count];
			} else if ([stats count] > 0) {
				Statistics *stat = [stats lastObject];
				if ([stat fillRatio] > 0.1) {
					sumFilledWordCount += [[obj words] count];
				}
			}
		}];
		
		return [NSString stringWithFormat:@"Package: %@ (sum: %lu cards, filled: %lu cards)", packageName, sumWordCount, sumFilledWordCount];
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
