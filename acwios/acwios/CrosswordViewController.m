//
//  CrosswordViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 08. 20..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CrosswordViewController.h"
#import "CrosswordCell.h"
#import "CrosswordLayout.h"

@interface CrosswordViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *crosswordView;
@property (weak, nonatomic) IBOutlet CrosswordLayout *crosswordLayout;

@end

@implementation CrosswordViewController

#pragma mark - Implementation

- (NSInteger) getRowFromIndexPath:(NSIndexPath*)indexPath {
	return indexPath.section;
}

- (NSInteger) getColFromIndexPath:(NSIndexPath*)indexPath {
	return indexPath.row;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //[self.collectionView registerClass:[CrosswordCell class] forCellWithReuseIdentifier:cellReusableIdentifier];
    
    // Do any additional setup after loading the view.
	[_crosswordLayout setCellWidth:50];
	[_crosswordLayout setCellHeight:50];
	[_crosswordLayout setRowCount:[_savedCrossword width]];
	[_crosswordLayout setColumnCount:[_savedCrossword height]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [_crosswordLayout rowCount];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_crosswordLayout columnCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CrosswordCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CWCell" forIndexPath:indexPath];
	if (cell) {
		//[cell setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		
		UILabel *fullLabel = [cell fullLabel];
		[fullLabel setHidden:NO];
		
		NSString *content = [NSString stringWithFormat:@"%li, %li", indexPath.section, indexPath.row];
		[fullLabel setText:content];
		
		[[cell topLabel] setHidden:YES];
		[[cell bottomLabel] setHidden:YES];
	}
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
