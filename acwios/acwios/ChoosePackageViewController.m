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
#import "GameTableCell.h"

@interface ChoosePackageViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *configureButton;
@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UITableView *packageTable;

@end

@implementation ChoosePackageViewController {
	BOOL _isSubscribed;
	NSArray<Package*>* _packages;
	NSMutableDictionary<NSURL*, NSNumber*>* _openStateOfPackages;
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

-(BOOL) sectionHasSomeSelectedCells:(NSInteger)section {
	__block BOOL foundSelected = NO;

	NSArray<NSIndexPath*> *selectedRows = [self->_packageTable indexPathsForSelectedRows];
	[selectedRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
		if (indexPath.section == section) {
			foundSelected = YES;
			*stop = YES;
		}
	}];
	
	return foundSelected;
}

-(void) deselectSelectedRows:(UITableView*)tableView notInSection:(NSInteger)section {
	NSArray<NSIndexPath*> *selectedRows = [tableView indexPathsForSelectedRows];
	[selectedRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (section != obj.section) {
			[tableView deselectRowAtIndexPath:obj animated:YES];
			[self setSectionHeaderSelectionState:tableView section:obj.section selectAll:YES];
		}
	}];
}

-(void) setSectionHeaderSelectionState:(UITableView*)tableView section:(NSInteger)section selectAll:(BOOL)selectAll {
	PackageSectionHeaderCell *sectionHeaderCell = [tableView viewWithTag:1000 + section];
	if (sectionHeaderCell) {
		if (selectAll) {
			[sectionHeaderCell setSelectAll];
		} else {
			[sectionHeaderCell setDeselectAll];
		}
	}
}

-(void) enableConfigureButtonUponSelection:(UITableView*)tableView {
	NSArray<NSIndexPath*> *selectedRows = [tableView indexPathsForSelectedRows];
	if ([selectedRows count] > 0) {
		[_configureButton setEnabled:YES];
	} else {
		[_configureButton setEnabled:NO];
	}
}

-(void) deletePackage:(Package*)package {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do You want to delete this package?"
																   message:@"All of Your already generated crosswords in this package will be deleted too! You cannot undo this action."
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
			NSError *err = nil;
			if ([[NSFileManager defaultManager] removeItemAtURL:[package path] error:&err] != YES) {
				NSLog (@"Cannot remove package at path: %@, error: %@", [package path], err);
			}

			[self reloadPackages];
			[self->_packageTable reloadData];
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
	[_subscribeView setHidden:_isSubscribed];
	
	[_configureButton setEnabled:NO];

	[self reloadPackages];
	
	_openStateOfPackages = [NSMutableDictionary<NSURL*, NSNumber*> new];
	[_packages enumerateObjectsUsingBlock:^(Package * _Nonnull package, NSUInteger idx, BOOL * _Nonnull stop) {
		[self->_openStateOfPackages setObject:[NSNumber numberWithBool:YES] forKey:[package path]];
	}];
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

			//Refresh opened and closed state of the section
			__block NSNumber *packageOpened = [self->_openStateOfPackages objectForKey:[package path]];
			if ([packageOpened boolValue]) {
				[sectionHeaderCell setOpened];
			} else {
				[sectionHeaderCell setClosed];
			}
			
			[self enableConfigureButtonUponSelection:self->_packageTable];

			//Refresh selected/deselected state
			if ([self sectionHasSomeSelectedCells:section]) {
				[sectionHeaderCell setDeselectAll];
			} else {
				[sectionHeaderCell setSelectAll];
			}
			
			//Set text
			NSString *titleText = [[NSString stringWithFormat:@"Package: %@", [package name]] uppercaseString];
			[[sectionHeaderCell titleLabel] setText:titleText];
			
			//Set tag
			[sectionHeaderCell setTag:1000 + section];
			
			//Set button callbacks
			__block __weak PackageSectionHeaderCell *weakSectionHeaderCell = sectionHeaderCell;
			[sectionHeaderCell setOpenCloseCallback:^{
				NSNumber *currentPackageState = [self->_openStateOfPackages objectForKey:[package path]];
				NSNumber *newPackageState = [NSNumber numberWithBool:[currentPackageState boolValue] ? NO : YES];
				[self->_openStateOfPackages setObject:newPackageState forKey:[package path]];

				[self->_packageTable reloadData];
			}];
			[sectionHeaderCell setSelectDeselectCallback:^{
				if ([packageOpened boolValue]) {
					if ([self sectionHasSomeSelectedCells:section]) { //Deselect all
						NSArray<NSIndexPath*> *selectedRows = [self->_packageTable indexPathsForSelectedRows];
						[selectedRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
							if (indexPath.section == section) {
								[self->_packageTable deselectRowAtIndexPath:indexPath animated:YES];
							}
						}];
						
						[weakSectionHeaderCell setSelectAll];
					} else { //Select all
						[self deselectSelectedRows:tableView notInSection:section];

						NSInteger rowsOfSection = [self->_packageTable numberOfRowsInSection:section];
						for (NSInteger i = 0; i < rowsOfSection; ++i) {
							NSIndexPath *selIP = [NSIndexPath indexPathForRow:i inSection:section];
							[self->_packageTable selectRowAtIndexPath:selIP animated:YES scrollPosition:UITableViewScrollPositionNone];
						}
						
						[weakSectionHeaderCell setDeselectAll];
					}
					
					[self enableConfigureButtonUponSelection:self->_packageTable];
				}
			}];
			[sectionHeaderCell setDeleteCallback:^{
				[self deletePackage:package];
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
	return 58;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section >= 0 && section < [_packages count]) {
		Package* package = [_packages objectAtIndex:section];
		NSNumber *packageOpened = [_openStateOfPackages objectForKey:[package path]];
		if ([packageOpened boolValue]) {
			return [[package decks] count];
		}
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	GameTableCell *cell = (GameTableCell*) [tableView dequeueReusableCellWithIdentifier:@"PackageCell" forIndexPath:indexPath];
	if (cell && indexPath.section >= 0 && indexPath.section < [_packages count]) {
		Package* pack = [_packages objectAtIndex:indexPath.section];

		//Set text color
		BOOL packEnabled = (indexPath.section < 1 && indexPath.row < 1) || _isSubscribed;
		[cell setSubscribed:packEnabled];
		
		//Set text
		NSArray<Deck*> *decks = [pack decks];
		if (indexPath.row >= 0 && indexPath.row < [decks count]) {
			Deck *deck = [decks objectAtIndex:indexPath.row];
			[cell.textLabel setText:[deck name]];
		}
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self enableConfigureButtonUponSelection:tableView];
	if ([self sectionHasSomeSelectedCells:indexPath.section] == NO) {
		[self setSectionHeaderSelectionState:tableView section:indexPath.section selectAll:YES];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self enableConfigureButtonUponSelection:tableView];
	[self deselectSelectedRows:tableView notInSection:indexPath.section];
	[self setSectionHeaderSelectionState:tableView section:indexPath.section selectAll:NO];
}

@end
