//
//  SUIChooseCWViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "SUIChooseCWViewController.h"
#import "SubscriptionManager.h"
#import "PackageManager.h"
#import "CWCell.h"
#import "NetLogger.h"

@interface SUIChooseCWViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *crosswordTable;
@property (weak, nonatomic) IBOutlet UINavigationItem *navItem;
@property (weak, nonatomic) IBOutlet UIView *helpOfPlusButton;

@end

@implementation SUIChooseCWViewController {
	BOOL _isSubscribed;
	NSMutableArray<NSString*> *_sortedPackageNames;
	NSMutableDictionary<NSString*, Package*> *_packages;
	NSDictionary<NSString*, NSArray<SavedCrossword*>*> *_savedCrosswords;
	SavedCrossword *_selectedCrossword;
}

#pragma mark - Implementation

-(void) showSubscription {
	[[SubscriptionManager sharedInstance] showSubscriptionAlert:self
															msg:@"You have to subscribe to the application to play the disabled crosswords! If you press yes, then we take you to our store screen to do that."];
}

-(void)reloadPackages {
	PackageManager *man = [PackageManager sharedInstance];
	NSArray<Package*> *packs = [man collectPackages];
	
	_sortedPackageNames = [NSMutableArray new];
	_packages = [NSMutableDictionary new];
	[packs enumerateObjectsUsingBlock:^(Package * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[self->_sortedPackageNames addObject:[obj name]];
		[self->_packages setObject:obj forKey:[obj name]];
	}];
	
	[_sortedPackageNames sortUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
		return [obj1 compare:obj2];
	}];
	
	_savedCrosswords = [man collectSavedCrosswords];
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
		NSString *packageName = [self->_sortedPackageNames objectAtIndex:indexPath.row];
		Package *package = [self->_packages objectForKey:packageName];
		[NetLogger logEvent:@"SUIChooseCW_DeleteCW" withParameters:@{ @"package" : [[package path] lastPathComponent] }];

		NSError *err = nil;
		if ([[NSFileManager defaultManager] removeItemAtURL:[package path] error:&err] != YES) {
			NSLog (@"Cannot remove package at path: %@, error: %@", [package path], err);
		}

		[self reloadPackages];
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
	
	[NetLogger logEvent:@"SUIChooseCW_ShowView"];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[[self subscribeView] setHidden:_isSubscribed];
	
	[self reloadPackages];
	BOOL hasSomePackages = [_sortedPackageNames count] > 0;

	__block BOOL hasSomeCrossword = NO;
	if (hasSomePackages) {
		[_savedCrosswords enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<SavedCrossword *> * _Nonnull obj, BOOL * _Nonnull stop) {
			if ([obj count] > 0) {
				hasSomeCrossword = YES;
				*stop = YES;
			}
		}];
	}
	
	[_navItem.rightBarButtonItem setEnabled:hasSomePackages];
	[_helpOfPlusButton setHidden:!hasSomePackages || hasSomeCrossword];
	
	[_crosswordTable reloadData];
}

- (IBAction)subscribeButtonPressed:(id)sender {
	[[SubscriptionManager sharedInstance] showStore:self];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier compare:@"ShowCW"] == NSOrderedSame) {
		NSIndexPath *selectedRow = [_crosswordTable indexPathForSelectedRow];
		
		BOOL cwEnabled = [selectedRow row] < 1 || self->_isSubscribed;
		if (!cwEnabled) {
			[self showSubscription];
		} else {
//			NSString* packageName = [[_savedCrosswords allKeys] objectAtIndex:[selectedRow section]];
//			_selectedCrossword = [[_savedCrosswords objectForKey:packageName] objectAtIndex:[selectedRow row]];
//			return YES;
		}
	} else if ([identifier compare:@"ShowDownload"] == NSOrderedSame) {
		return YES;
	}
	
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

#pragma mark - Package Table DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_sortedPackageNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	CWCell *cell = (CWCell*) [tableView dequeueReusableCellWithIdentifier:@"CWCell" forIndexPath:indexPath];
	if (cell && indexPath.row >= 0 && indexPath.row < [_sortedPackageNames count]) {
		NSString *packageName = [_sortedPackageNames objectAtIndex:indexPath.row];
		
		BOOL cwEnabled = indexPath.row < 1 || _isSubscribed;
		[cell setSubscribed:cwEnabled];
		
		[cell.packageName setText:packageName];
		[cell.statistics setText:[NSString stringWithFormat:@"%lu of %lu levels (%lu of %lu words) solved", 0ul, 0ul, 0ul, 0ul]];

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
			   title:@"Delete crossword"
			   handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
				   [self deleteCrosswordAt:indexPath];
			   }]
			  ];
}

@end
