//
//  SUIChooseCWViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "SUIChooseCWViewController.h"
#import "CrosswordViewController.h"
#import "AnkiDownloadViewController.h"
#import "SubscriptionManager.h"
#import "PackageManager.h"
#import "CWCell.h"
#import "NetLogger.h"
#include <stdlib.h>

@interface SUIChooseCWViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *crosswordTable;
@property (weak, nonatomic) IBOutlet UINavigationItem *navItem;
@property (weak, nonatomic) IBOutlet UIView *helpOfPlusButton;

@end

@implementation SUIChooseCWViewController {
	BOOL _isSubscribed;
	NSMutableArray<NSString*> *_sortedPackageKeys; ///< The keys of the packages sorted by package name
	NSMutableDictionary<NSString*, Package*> *_packages;
	NSMutableDictionary<NSString*, NSNumber*> *_currentSavedCrosswordIndices; ///< The index of the currently played crossword of packages
	NSMutableDictionary<NSString*, NSNumber*> *_filledWordCounts; ///< The filled word counts of packages
	NSDictionary<NSString*, NSArray<SavedCrossword*>*> *_savedCrosswords; ///< All of the generated crosswords of packages
	NSString* _selectedPackageKey;
	NSUInteger _selectedCrosswordIndex;
	BOOL _isRandomGame;
}

#pragma mark - Implementation

-(void) showSubscription {
	[[SubscriptionManager sharedInstance] showSubscriptionAlert:self
															msg:NSLocalizedString (@"subscribe_take_to_store", @"")];
}

-(void) showSubscriptionOnDelete {
	[[SubscriptionManager sharedInstance] showSubscriptionAlert:self
															msg:NSLocalizedString (@"subscribe_on_delete_warning", @"")];
}

-(void)reloadPackages {
	_selectedPackageKey = nil;
	_selectedCrosswordIndex = 0;
	_isRandomGame = NO;
	
	PackageManager *man = [PackageManager sharedInstance];
	NSArray<Package*> *packs = [man collectPackages];
	_savedCrosswords = [man collectSavedCrosswords];

	_sortedPackageKeys = [NSMutableArray new];
	_packages = [NSMutableDictionary new];
	[packs enumerateObjectsUsingBlock:^(Package * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString *packageKey = [obj getPackageKey];
		if ([[self->_savedCrosswords objectForKey:packageKey] count] > 0) {
			[self->_sortedPackageKeys addObject:packageKey];
			[self->_packages setObject:obj forKey:packageKey];
		}
	}];
	
//	[_sortedPackageKeys sortUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
//		Package *pack1 = [self->_packages objectForKey:obj1];
//		Package *pack2 = [self->_packages objectForKey:obj2];
//
//		NSString *name1 = pack1.state.overriddenPackageName;
//		if ([name1 length] <= 0) {
//			name1 = pack1.name;
//		}
//
//		NSString *name2 = pack2.state.overriddenPackageName;
//		if ([name2 length] <= 0) {
//			name2 = pack2.name;
//		}
//
//		return [name1 compare:name2];
//	}];
	
	_currentSavedCrosswordIndices = [NSMutableDictionary new];
	_filledWordCounts = [NSMutableDictionary new];
	[_sortedPackageKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull packageKey, NSUInteger idx, BOOL * _Nonnull stop) {
		__block Package *package = [self->_packages objectForKey:packageKey];
		NSArray<SavedCrossword*> *cws = [self->_savedCrosswords objectForKey:packageKey];
		
		__block NSUInteger currentIdx = [cws indexOfObjectPassingTest:^BOOL(SavedCrossword * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if ([[obj name] compare:package.state.crosswordName] == NSOrderedSame) {
				return YES;
			}
			return NO;
		}];
		if (currentIdx == NSNotFound) {
			currentIdx = 0;
		}
		
		NSNumber *curCWIdx = nil;
		if (package.state.filledLevel >= package.state.levelCount) {
			curCWIdx = [NSNumber numberWithUnsignedInteger:currentIdx + 1];
		} else {
			curCWIdx = [NSNumber numberWithUnsignedInteger:currentIdx];
		}
		
		[self->_currentSavedCrosswordIndices setObject:curCWIdx forKey:packageKey];
		
		__block NSUInteger sumWordCount = 0;
		[cws enumerateObjectsUsingBlock:^(SavedCrossword * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if (idx == currentIdx) {
				*stop = YES;
				return;
			}
			
			sumWordCount += [[obj words] count];
		}];
		
		[self->_filledWordCounts setObject:[NSNumber numberWithUnsignedInteger:sumWordCount] forKey:packageKey];
	}];
}

-(void) deleteCrosswordAt:(NSIndexPath*)indexPath {
	if (!_isSubscribed) {
		[self showSubscriptionOnDelete];
		return;
	}
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString (@"do_you_want_delete_cw", @"")
																   message:NSLocalizedString (@"cannot_undo_this_action", @"")
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *actionNo = [UIAlertAction actionWithTitle:NSLocalizedString (@"cancel", @"")
													   style:UIAlertActionStyleCancel
													 handler:^(UIAlertAction * _Nonnull action)
	{
		//Nothing to do here...
	}];
	
	[alert addAction:actionNo];
	
	UIAlertAction *actionYes = [UIAlertAction actionWithTitle:NSLocalizedString (@"delete", @"")
														style:UIAlertActionStyleDestructive
													  handler:^(UIAlertAction * _Nonnull action)
	{
		NSString *packageKey = [self->_sortedPackageKeys objectAtIndex:indexPath.row];
		Package *package = [self->_packages objectForKey:packageKey];
		[NetLogger logEvent:@"SUIChooseCW_DeleteCW" withParameters:@{ @"package" : [[package path] lastPathComponent] }];

		NSError *err = nil;
		if ([[NSFileManager defaultManager] removeItemAtURL:[package path] error:&err] != YES) {
			NSLog (@"Cannot remove package at path: %@, error: %@", [package path], err);
		}

		[self reloadPackages];

		BOOL hasSomePackages = [self->_sortedPackageKeys count] > 0;
		[self->_helpOfPlusButton setHidden:hasSomePackages];
		
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
	
	//TODO: localize random button
	//TODO: localize store message above the subscribe now button
	
	[NetLogger logEvent:@"SUIChooseCW_ShowView"];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[[self subscribeView] setHidden:_isSubscribed];
	
	[self reloadPackages];
	BOOL hasSomePackages = [_sortedPackageKeys count] > 0;
	
	[_navItem.rightBarButtonItem setEnabled:YES];
	[_helpOfPlusButton setHidden:hasSomePackages];
	
	[_crosswordTable reloadData];
}

- (IBAction)subscribeButtonPressed:(id)sender {
	[[SubscriptionManager sharedInstance] showStore:self];
}

- (void)randomButtonPressed:(id)sender {
	UIView *view = (UIView*)sender;
	while (![view isKindOfClass:[CWCell class]]) {
		view = [view superview];
	}
	
	CWCell *cell = (CWCell*)view;
	BOOL cwEnabled = [[_sortedPackageKeys objectAtIndex:0] compare:cell.packageKey] == NSOrderedSame || _isSubscribed;
	if (!cwEnabled) {
		[self showSubscription];
		return;
	}
	
	NSUInteger idx = [[_currentSavedCrosswordIndices objectForKey:cell.packageKey] unsignedIntegerValue];
	NSArray<NSNumber*> *randIndices = [[PackageManager sharedInstance] collectMinimalStatCountCWIndices:cell.packageKey savedCrosswords:_savedCrosswords playedCWCount:idx];
	
	uint32_t randIdx = arc4random_uniform ((uint32_t) randIndices.count);
	_selectedPackageKey = cell.packageKey;
	_selectedCrosswordIndex = [[randIndices objectAtIndex:randIdx] unsignedIntegerValue];
	_isRandomGame = YES;
	
	[self performSegueWithIdentifier:@"ShowCW" sender:self];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier compare:@"ShowCW"] == NSOrderedSame) {
		NSIndexPath *selectedRow = [_crosswordTable indexPathForSelectedRow];
		
		BOOL cwEnabled = [selectedRow row] < 1 || self->_isSubscribed;
		if (!cwEnabled) {
			[self showSubscription];
		} else {
			NSString *packageKey = [_sortedPackageKeys objectAtIndex:selectedRow.row];
			NSUInteger idx = [[_currentSavedCrosswordIndices objectForKey:packageKey] unsignedIntegerValue];
			_selectedPackageKey = packageKey;
			_selectedCrosswordIndex = idx;
			_isRandomGame = NO;
			return YES;
		}
	} else if ([identifier compare:@"ShowDownload"] == NSOrderedSame) {
		return YES;
	}
	
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowCW"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[UINavigationController class]])
	{
		UINavigationController *navController = (UINavigationController*) [segue destinationViewController];
		if ([[navController topViewController] isKindOfClass:[CrosswordViewController class]]) {
			CrosswordViewController *cwController = (CrosswordViewController*) [navController topViewController];
			NSArray<SavedCrossword*> *cws = [_savedCrosswords objectForKey:_selectedPackageKey];
			
			[cwController setCurrentPackage:[_packages objectForKey:_selectedPackageKey]];
			[cwController setSavedCrossword:[cws objectAtIndex:_selectedCrosswordIndex]];
			[cwController setCurrentCrosswordIndex:_selectedCrosswordIndex];
			[cwController setAllSavedCrossword:cws];
			[cwController setIsMultiLevelGame:!_isRandomGame];
		}
	} else if ([segue.identifier compare:@"ShowDownload"] == NSOrderedSame &&
			   [segue.destinationViewController isKindOfClass:[AnkiDownloadViewController class]])
	{
		AnkiDownloadViewController *downloadView = (AnkiDownloadViewController*) segue.destinationViewController;
		[downloadView setDoGenerationAfterAnkiDownload:YES];
	}
}

#pragma mark - Package Table DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_sortedPackageKeys count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	CWCell *cell = (CWCell*) [tableView dequeueReusableCellWithIdentifier:@"CWCell" forIndexPath:indexPath];
	if (cell && indexPath.row >= 0 && indexPath.row < [_sortedPackageKeys count]) {
		NSString *packageKey = [_sortedPackageKeys objectAtIndex:indexPath.row];
		NSUInteger filledLevelCount = [[_currentSavedCrosswordIndices objectForKey:packageKey] unsignedIntegerValue];
		NSUInteger filledWordCount = [[_filledWordCounts objectForKey:packageKey] unsignedIntegerValue];

		cell.parent = self;
		cell.packageKey = packageKey;
		
		Package *pack = [_packages objectForKey:packageKey];
		
		BOOL cwEnabled = indexPath.row < 1 || _isSubscribed;
		[cell setSubscribed:cwEnabled];
		
		NSString *title = pack.state.overriddenPackageName;
		if ([title length] <= 0) {
			title = pack.name;
		}
		[cell.packageName setText:title];
		[cell.statistics setText:[NSString stringWithFormat:NSLocalizedString (@"cell_statistics", @""),
								  filledLevelCount,
								  pack.state.levelCount,
								  pack.state.filledLevel >= pack.state.levelCount ? pack.state.wordCount : filledWordCount,
								  pack.state.wordCount]];

		if (cwEnabled) {
			[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		} else {
			[cell setAccessoryType:UITableViewCellAccessoryNone];
		}
	}
	return cell;
}

#pragma mark - Package Table Editing

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @[ [UITableViewRowAction
			   rowActionWithStyle:UITableViewRowActionStyleDestructive
			   title:NSLocalizedString (@"delete_crossword", @"")
			   handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
				   [self deleteCrosswordAt:indexPath];
			   }]
			  ];
}

@end
