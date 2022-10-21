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

@interface SUIChooseLevelViewController ()

@property (weak, nonatomic) IBOutlet UIView *subscribeView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *subscribeDescription;

@end

@implementation SUIChooseLevelViewController {
	BOOL _isSubscribed;
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[_subscribeDescription setText:NSLocalizedString (@"subscribe_warning", @"")];
    
	//Init collection view
	[_collectionView setDataSource:self];
	[_collectionView setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	[[self subscribeView] setHidden:_isSubscribed];
	
	//Reload collection view
	[_collectionView reloadData];
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Events

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
	//TOOD:...
}

@end
