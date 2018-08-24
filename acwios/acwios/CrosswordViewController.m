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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showHideButton;

@end

@implementation CrosswordViewController {
	BOOL _areAnswersVisible;
}

#pragma mark - Implementation

- (uint32_t) getRowFromIndexPath:(NSIndexPath*)indexPath {
	return (uint32_t) indexPath.section;
}

- (uint32_t) getColFromIndexPath:(NSIndexPath*)indexPath {
	return (uint32_t) indexPath.row;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //[self.collectionView registerClass:[CrosswordCell class] forCellWithReuseIdentifier:cellReusableIdentifier];
    
    // Do any additional setup after loading the view.
	_areAnswersVisible = NO;
	
	[_crosswordLayout setCellWidth:50];
	[_crosswordLayout setCellHeight:50];
	[_crosswordLayout setRowCount:[_savedCrossword height]];
	[_crosswordLayout setColumnCount:[_savedCrossword width]];
	[_crosswordLayout setStatusBarHeight:[UIApplication sharedApplication].statusBarFrame.size.height];
	[_crosswordLayout setNavigationBarHeight:self.navigationController.navigationBar.frame.size.height];
	
	[_savedCrossword loadDB];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
	[_savedCrossword unloadDB];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showHideButtonPressed:(id)sender {
	_areAnswersVisible = _areAnswersVisible ? NO : YES;
	[_showHideButton setTitle:_areAnswersVisible ? @"Hide answers" : @"Show answers"];
	[_crosswordView reloadData];
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
		uint32_t row = [self getRowFromIndexPath:indexPath];
		uint32_t col = [self getColFromIndexPath:indexPath];
		enum CWCellType cellType = [_savedCrossword getCellTypeInRow:row col:col];
		
		switch (cellType) {
			case CWCellType_SingleQuestion:
				[cell fillOneQuestion: [_savedCrossword getCellsQuestion:row col:col questionIndex:0]];
				break;
			case CWCellType_DoubleQuestion: {
				NSString* qTop = [_savedCrossword getCellsQuestion:row col:col questionIndex:0];
				NSString* qBottom = [_savedCrossword getCellsQuestion:row col:col questionIndex:1];
				[cell fillTwoQuestion:qTop questionBottom:qBottom];
				break;
			}
			case CWCellType_Spacer:
				[cell fillSpacer];
				break;
			case CWCellType_Letter: {
				NSString* cellValue = [_savedCrossword getCellsValue:row col:col];
				[cell fillLetter:_areAnswersVisible value:cellValue];
				break;
			}
			case CWCellType_Start_TopDown_Right:
			case CWCellType_Start_TopDown_Left:
			case CWCellType_Start_TopDown_Bottom:
			case CWCellType_Start_TopRight:
			case CWCellType_Start_FullRight:
			case CWCellType_Start_BottomRight:
			case CWCellType_Start_LeftRight_Top:
			case CWCellType_Start_LeftRight_Bottom: {
				NSString* cellValue = [_savedCrossword getCellsValue:row col:col];
				[cell fillArrow:cellType showValue:_areAnswersVisible value:cellValue];
				break;
			}
			default:
				break;
		}
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
