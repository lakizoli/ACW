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

@interface CWConfiguratorViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *crosswordTable;

@end

@implementation CWConfiguratorViewController {
	BOOL _isSubscribed;
	NSDictionary<NSString*, NSArray<SavedCrossword*>*> *_savedCrosswords;
	SavedCrossword *_selectedCrossword;
}

#pragma mark - Implementation

-(void) showSubscription {
	//TODO: implement subscribtion process in SubScriptionManager...
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subscribe" message:@"Let's take some subscription..." preferredStyle:UIAlertControllerStyleAlert];
	
	[self presentViewController:alert animated:YES completion:nil];
}

-(SavedCrossword*) savedCWFromIndexPath:(NSIndexPath*)indexPath {
	NSString *packageName = [[_savedCrosswords allKeys] objectAtIndex:indexPath.section];
	NSArray<SavedCrossword*> *cws = [_savedCrosswords objectForKey:packageName];
	return [cws objectAtIndex:indexPath.row];
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
	if ([identifier compare:@"ShowCrosswordView"] == NSOrderedSame) {
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
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CWCell" forIndexPath:indexPath];
	if (cell && indexPath.section >= 0 && indexPath.section < [_savedCrosswords count]) {
		SavedCrossword *cw = [self savedCWFromIndexPath:indexPath];
		if (cw) {
			BOOL cwEnabled = indexPath.row < 1 || _isSubscribed;
			if (cwEnabled) { //Enabled
				[cell.textLabel setTextColor:[UIColor blackColor]];
			} else { //Disabled
				[cell.textLabel setTextColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
			}

			NSString *label = [NSString stringWithFormat:@"[%dx%d] (%d cards) - %@", [cw width], [cw height], [cw wordCount], [cw name]];
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
				   SavedCrossword *cw = [self savedCWFromIndexPath:indexPath];
				   if (cw) {
					   NSError *err = nil;
					   if ([[NSFileManager defaultManager] removeItemAtURL:[cw path] error:&err] != YES) {
						   NSLog (@"Cannot delete crossword at path: %@, error: %@", [cw path], err);
					   }
				   }
				   
				   self->_savedCrosswords = [[PackageManager sharedInstance] collectSavedCrosswords];
				   [tableView reloadData];
			   }]
			];
}

@end
