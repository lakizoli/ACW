//
//  SUIChooseLevelViewController.m
//  acwios
//
//  Created by Zoli on 2022. 10. 20..
//  Copyright © 2022. ZApp. All rights reserved.
//

#import "SUIChooseLevelViewController.h"
#import "LevelCell.h"
#import "SubscriptionManager.h"
#import "CrosswordViewController.h"
#import "NetLogger.h"

@interface SUIChooseLevelViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *subscribeDescription;

@end

@implementation SUIChooseLevelViewController {
	BOOL _isSubscribed;
	NSInteger _lastUnlockedCWIndex;
	NSInteger _choosenCWIndex;
}

#pragma mark - Implementation

-(void) showSubscription {
	[[SubscriptionManager sharedInstance] showSubscriptionAlert:self
															msg:NSLocalizedString (@"subscribe_take_to_store", @"")];
}

-(void) showLockedAlert {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString (@"warning_title", @"")
																   message:NSLocalizedString (@"locked_cw_msg", @"")
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:NSLocalizedString (@"ok", @"")
													   style:UIAlertActionStyleCancel
													 handler:^(UIAlertAction * _Nonnull action)
	{
		//[self dismissViewControllerAnimated:YES completion:nil];
		//...nothing to do here...
	}];
	
	[alert addAction:actionOK];
	
	[self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)hasValidChoosenCWIndex {
	return _choosenCWIndex >= 0 && _choosenCWIndex < [[_currentPackage decks] count];
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier compare:@"ShowCW"] == NSOrderedSame) {
		return [self hasValidChoosenCWIndex];
	}
	
	return NO;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowCW"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[UINavigationController class]] &&
		[self hasValidChoosenCWIndex])
	{
		UINavigationController *navController = (UINavigationController*) [segue destinationViewController];
		if ([[navController topViewController] isKindOfClass:[CrosswordViewController class]]) {
			CrosswordViewController *cwController = (CrosswordViewController*) [navController topViewController];

			[cwController setCurrentPackage:_currentPackage];
			[cwController setSavedCrossword:[_allSavedCrossword objectAtIndex:_choosenCWIndex]];
			[cwController setCurrentCrosswordIndex:_choosenCWIndex];
			[cwController setAllSavedCrossword:_allSavedCrossword];
			[cwController setIsMultiLevelGame:YES];
		}
	}
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[_subscribeDescription setText:NSLocalizedString (@"subscribe_warning", @"")];
    
	//Init collection view
	[_collectionView setDataSource:self];
	[_collectionView setDelegate:self];
	
	[NetLogger logEvent:@"SUIChooseLevel_ShowView"];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	_lastUnlockedCWIndex = 0;
	_choosenCWIndex = -1;
	
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[[self subscribeView] setHidden:_isSubscribed];
	
	//Reload collection view
	[_collectionView reloadData];
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)subscribeButtonPressed:(id)sender {
	[[SubscriptionManager sharedInstance] showStore:self];
}

#pragma mark - Collection DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [_allSavedCrossword count];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
	NSString *reuseID = @"LevelCell";
	LevelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
	if (cell == nil) {
		cell = [[LevelCell alloc] init];
	}
	
	cell.textView.text = [NSString stringWithFormat:@"%d", (int32_t) indexPath.row + 1];
	
	[cell setState:indexPath.row lastPlayedLevel:_currentCrosswordIndex isSubscribed:_isSubscribed];
	if (![cell isLocked] && indexPath.row > _lastUnlockedCWIndex) {
		_lastUnlockedCWIndex = indexPath.row;
	}
	
	return cell;
}

#pragma mark - Collection Delegates

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake (30, 30, 30, 30);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return 15;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 15;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return CGSizeMake (50, 50);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger cwIndex = indexPath.row;
	
	if (cwIndex > _lastUnlockedCWIndex) { //this is a locked crossword
		if (_isSubscribed) { //this cw is unreachable because it is not reached yet
			[self showLockedAlert];
		} else { //this cw is unreachable because the user is not subscribed yet
			[self showSubscription];
		}
		return;
	}
	
	_choosenCWIndex = cwIndex;
	[self performSegueWithIdentifier:@"ShowCW" sender:self];
}

@end
