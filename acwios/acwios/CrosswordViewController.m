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
#import "KeyboardViewController.h"

//TODO: show custom (owner draw) keyboard with all characters used by the crossword!
//TODO: implement statistics!

@interface CrosswordViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *crosswordView;
@property (weak, nonatomic) IBOutlet CrosswordLayout *crosswordLayout;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showHideButton;

@end

@implementation CrosswordViewController {
	BOOL _areAnswersVisible;
	NSMutableDictionary<NSIndexPath*, NSString*> *_cellFilledValues; ///< The current fill state of the whole grid.

	//Text input data
	BOOL _canBecameFirstResponder;
	NSString *_currentAnswer;
	uint32_t _maxAnswerLength;
	int32_t _startCellRow;
	int32_t _startCellCol;
	int32_t _answerIndex; ///< The rolling index of the current answer selected for input, when multiple answers are available in a start cell.
	NSMutableArray<NSNumber*> *_availableAnswerDirections; ///< All of the available input directions can be originated from the current start cell.
}

#pragma mark - Implementation

- (NSIndexPath*) getIndexPathForRow:(NSInteger)row col:(NSInteger)col {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:col inSection:row]; //row is the secion, and col is the row!
	return indexPath;
}

- (uint32_t) getRowFromIndexPath:(NSIndexPath*)indexPath {
	return (uint32_t) indexPath.section;
}

- (uint32_t) getColFromIndexPath:(NSIndexPath*)indexPath {
	return (uint32_t) indexPath.row;
}

-(void) commitValidAnswer {
	//Copy value into fill table
	NSUInteger len = [_currentAnswer length];
	if (len > 0) {
		_currentAnswer = [_currentAnswer lowercaseString];
		
		if ([self isInputInHorizontalDirection]) { //Horizontal answer
			//Check answers validity
			BOOL validAnswerFound = YES;
			uint32_t answerLen = [_savedCrossword width] - _startCellCol;
			for (uint32_t col = _startCellCol, colEnd = [_savedCrossword width]; col < colEnd; ++col) {
				uint32_t cellType = [_savedCrossword getCellTypeInRow:_startCellRow col:col];
				if ((cellType & CWCellType_HasValue) == 0) { //We reach the end of this value
					answerLen = col - _startCellCol;
					break;
				}
				
				if ([_currentAnswer length] <= col - _startCellCol) {
					validAnswerFound = NO;
					break;
				}

				NSString *cellValue = [_savedCrossword getCellsValue:_startCellRow col:col];
				if ([cellValue length] > 0 &&
					[_currentAnswer characterAtIndex:col - _startCellCol] != [cellValue characterAtIndex:0]) //We found an invalid character
				{
					validAnswerFound = NO;
					break;
				}
			}
			
			if (answerLen == len && validAnswerFound) { //We have a valid answer
				//Copy values to grid
				for (NSUInteger i = 0; i < len; ++i) {
					NSString *val = [NSString stringWithFormat: @"%C", [_currentAnswer characterAtIndex:i]];
					NSIndexPath *path = [self getIndexPathForRow:_startCellRow col:_startCellCol + i];
					[_cellFilledValues setObject:val forKey:path];
				}
				
				//Save filled values
				[_savedCrossword saveFilledValues:_cellFilledValues];
			}
		} else { //Vertical answer
			//Check answers validity
			BOOL validAnswerFound = YES;
			uint32_t answerLen = [_savedCrossword height] - _startCellRow;
			for (uint32_t row = _startCellRow, rowEnd = [_savedCrossword height]; row < rowEnd; ++row) {
				uint32_t cellType = [_savedCrossword getCellTypeInRow:row col:_startCellCol];
				if ((cellType & CWCellType_HasValue) == 0) { //We reach the end of this value
					answerLen = row - _startCellRow;
					break;
				}
				
				if ([_currentAnswer length] <= row - _startCellRow) {
					validAnswerFound = NO;
					break;
				}
				
				NSString *cellValue = [_savedCrossword getCellsValue:row col:_startCellCol];
				if ([cellValue length] > 0 &&
					[_currentAnswer characterAtIndex:row - _startCellRow] != [cellValue characterAtIndex:0]) //We found an invalid character
				{
					validAnswerFound = NO;
					break;
				}
			}
			
			if (answerLen == len && validAnswerFound) { //We have a valid answer
				//Copy values to grid
				for (NSUInteger i = 0; i < len; ++i) {
					NSString *val = [NSString stringWithFormat: @"%C", [_currentAnswer characterAtIndex:i]];
					NSIndexPath *path = [self getIndexPathForRow:_startCellRow + i col:_startCellCol];
					[_cellFilledValues setObject:val forKey:path];
				}
				
				//Save filled values
				[_savedCrossword saveFilledValues:_cellFilledValues];
			}
		}
	}
}

-(void) resetInput {
	_currentAnswer = nil;
	_canBecameFirstResponder = NO;
	_maxAnswerLength = 0;
	_startCellCol = -1;
	_startCellRow = -1;
	_availableAnswerDirections = nil;
	_answerIndex = -1;

	[self resignFirstResponder];
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //[self.collectionView registerClass:[CrosswordCell class] forCellWithReuseIdentifier:cellReusableIdentifier];
    
    // Do any additional setup after loading the view.
	_inputViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"KeyboardVC"];
	
	_areAnswersVisible = NO;
	_cellFilledValues = [NSMutableDictionary<NSIndexPath*, NSString*> new];
	[_savedCrossword loadFilledValuesInto:_cellFilledValues];
	
	[self resetInput];
	[self registerForKeyboardNotifications];
	
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
	[_showHideButton setTitle:_areAnswersVisible ? @"Hide Hint" : @"Show Hint"];
	[_crosswordView reloadData];
}

- (IBAction)resetButtonPressed:(id)sender {
	[_cellFilledValues removeAllObjects];
	[_savedCrossword saveFilledValues:_cellFilledValues];
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

#pragma mark - UICollectionViewDataSource

-(BOOL) isInputInHorizontalDirection {
	BOOL res = NO;
	if (_answerIndex >= 0 && _answerIndex < [_availableAnswerDirections count]) {
		enum CWCellType currentDir = (enum CWCellType) [[_availableAnswerDirections objectAtIndex:_answerIndex] unsignedIntegerValue];
		if (currentDir == CWCellType_Start_TopRight || currentDir == CWCellType_Start_FullRight ||
			currentDir == CWCellType_Start_BottomRight || currentDir == CWCellType_Start_LeftRight_Top ||
			currentDir == CWCellType_Start_LeftRight_Bottom) //Horizontal answer direction
		{
			res = YES;
		}
	}
	return res;
}

-(void) fillLetterForCell:(CrosswordCell*)cell row:(uint32_t)row col:(uint32_t)col {
	BOOL fillValue = NO;
	NSString* cellValue;
	if (_areAnswersVisible) {
		fillValue = YES;
		cellValue = [_savedCrossword getCellsValue:row col:col];
	} else {
		//Get value from current answer if available
		if (_currentAnswer != nil) {
			if ([self isInputInHorizontalDirection]) { //Horizontal answer
				if (row == _startCellRow && col >= _startCellCol && col < (_startCellCol + [_currentAnswer length])) {
					fillValue = YES;
					cellValue = [_currentAnswer substringWithRange:NSMakeRange (col - _startCellCol, 1)];
				}
			} else { //Vertical answer
				if (col == _startCellCol && row >= _startCellRow && row < (_startCellRow + [_currentAnswer length])) {
					fillValue = YES;
					cellValue = [_currentAnswer substringWithRange:NSMakeRange (row - _startCellRow, 1)];
				}
			}
		}
	
		//Fill value from filled values
		if (!fillValue) {
			NSIndexPath *path = [self getIndexPathForRow:row col:col];
			NSString *value = [_cellFilledValues objectForKey:path];
			if (value) {
				fillValue = YES;
				cellValue = value;
			}
		}
	}
	
	[cell fillLetter:fillValue value:cellValue];
}

-(void) fillCellsArrow:(uint32_t)cellType
		 checkCellType:(enum CWCellType)checkCellType
				  cell:(CrosswordCell*)cell
				   row:(uint32_t)row
				   col:(uint32_t)col
		  letterFilled:(BOOL*)letterFilled
{
	if (cellType & checkCellType) {
		if (*letterFilled != YES) {
			[self fillLetterForCell:cell row:row col:col];
			*letterFilled = YES;
		}
		[cell fillArrow:checkCellType];
	}
}

-(void) addAvailableInputDirection:(uint32_t)cellType checkCellType:(enum CWCellType)checkCellType {
	if (cellType & checkCellType) {
		[_availableAnswerDirections addObject:[NSNumber numberWithUnsignedInteger:checkCellType]];
	}
}

-(void) ensureVisibleRow:(uint32_t)row col:(uint32_t)col {
	NSIndexPath *path = [self getIndexPathForRow:row col:col];
	[_crosswordView scrollToItemAtIndexPath:path
						   atScrollPosition:UICollectionViewScrollPositionCenteredVertically | UICollectionViewScrollPositionCenteredHorizontally
								   animated:YES];
}

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
		uint32_t cellType = [_savedCrossword getCellTypeInRow:row col:col];
		
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
			case CWCellType_Letter:
				[self fillLetterForCell:cell row:row col:col];
				[cell fillSeparator:[_savedCrossword getCellsSeparators:row col:col]];
				break;
			default: {
				BOOL letterFilled = NO;
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Right cell:cell row:row col:col letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Left cell:cell row:row col:col letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Bottom cell:cell row:row col:col letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopRight cell:cell row:row col:col letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_FullRight cell:cell row:row col:col letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_BottomRight cell:cell row:row col:col letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_LeftRight_Top cell:cell row:row col:col letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_LeftRight_Bottom cell:cell row:row col:col letterFilled:&letterFilled];
				[cell fillSeparator:[_savedCrossword getCellsSeparators:row col:col]];
				break;
			}
		}
	}
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	//Determine answer's current direction
	uint32_t selRow = [self getRowFromIndexPath:indexPath];
	uint32_t selCol = [self getColFromIndexPath:indexPath];
	BOOL isNewStart = _startCellRow < 0 || _startCellCol < 0 || _answerIndex < 0 || _startCellRow != selRow || _startCellCol != selCol;
	if (isNewStart) {
		//Collect available answer directions
		_availableAnswerDirections = [NSMutableArray<NSNumber*> new];
		uint32_t cellType = [_savedCrossword getCellTypeInRow:selRow col:selCol];
		[self addAvailableInputDirection:cellType checkCellType:CWCellType_Start_TopDown_Right];
		[self addAvailableInputDirection:cellType checkCellType:CWCellType_Start_TopDown_Left];
		[self addAvailableInputDirection:cellType checkCellType:CWCellType_Start_TopDown_Bottom];
		[self addAvailableInputDirection:cellType checkCellType:CWCellType_Start_TopRight];
		[self addAvailableInputDirection:cellType checkCellType:CWCellType_Start_FullRight];
		[self addAvailableInputDirection:cellType checkCellType:CWCellType_Start_BottomRight];
		[self addAvailableInputDirection:cellType checkCellType:CWCellType_Start_LeftRight_Top];
		[self addAvailableInputDirection:cellType checkCellType:CWCellType_Start_LeftRight_Bottom];
		if ([_availableAnswerDirections count] <= 0) { //Basic error check (one direction have to be available!)
			return;
		}

		//Start input of first answer
		_startCellRow = selRow;
		_startCellCol = selCol;
		_answerIndex = 0;
	} else {
		++_answerIndex;
		if (_answerIndex >= [_availableAnswerDirections count]) {
			_answerIndex = 0;
		}
	}
	
	//Determine answer's available length
	_maxAnswerLength = 0;
	if ([self isInputInHorizontalDirection]) {
		BOOL endReached = NO;
		while (!endReached) {
			++_maxAnswerLength;
			
			uint32_t cellType = [_savedCrossword getCellTypeInRow:selRow col:selCol + _maxAnswerLength];
			if (cellType == CWCellType_Unknown || cellType == CWCellType_SingleQuestion ||
				cellType == CWCellType_DoubleQuestion || cellType == CWCellType_Spacer) //End of current input word reached
			{
				endReached = YES;
			}
		}
	} else {
		BOOL endReached = NO;
		while (!endReached) {
			++_maxAnswerLength;
			
			uint32_t cellType = [_savedCrossword getCellTypeInRow:selRow + _maxAnswerLength col:selCol];
			if (cellType == CWCellType_Unknown || cellType == CWCellType_SingleQuestion ||
				cellType == CWCellType_DoubleQuestion || cellType == CWCellType_Spacer) //End of current input word reached
			{
				endReached = YES;
			}
		}
	}
	
	//Show keyboard
	[self becomeFirstResponder];
	_currentAnswer = nil;
	
	//Ensure visibility of value is under entering
	[self ensureVisibleRow:selRow col:selCol];

	//TODO: highlite word have to be enter!
	
	//NSLog (@"did select item at index path: %@", [indexPath description]);
}

#pragma mark - UICollectionViewDelegate

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	uint32_t row = [self getRowFromIndexPath:indexPath];
	uint32_t col = [self getColFromIndexPath:indexPath];
	BOOL startCell = [_savedCrossword isStartCell:row col:col];
	_canBecameFirstResponder = startCell;
	[self commitValidAnswer];
	if (startCell == YES) {
		_currentAnswer = nil;
	} else {
		[self resetInput];
	}
    return startCell;
}

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

#pragma mark - UIResponder protocol

- (BOOL)canBecomeFirstResponder {
	return _canBecameFirstResponder;
}

#pragma mark - UIKeyInput protocol

-(BOOL) hasText {
	return [_currentAnswer length] > 0;
}

- (void)deleteBackward {
	//Alter answer
	NSUInteger len = [_currentAnswer length];
	if (len > 1) {
		_currentAnswer = [_currentAnswer substringToIndex:(len - 1)];
	} else if (len == 1) {
		_currentAnswer = nil;
	}
	
	//Ensure visibility of next char to enter
	if ([self isInputInHorizontalDirection]) {
		[self ensureVisibleRow:_startCellRow col:_startCellCol + (uint32_t) [_currentAnswer length]];
	} else {
		[self ensureVisibleRow:_startCellRow + (uint32_t) [_currentAnswer length] col:_startCellCol];
	}

	//Fill grid
	[_crosswordView reloadData];
}

- (void)insertText:(nonnull NSString *)text {
	//Handle input
	if ([text isEqualToString:@"\n"]) { //Handle press of return (done button)
		[self commitValidAnswer];
		[self resetInput];
	} else { //Handle normal keys
		//Check available length
		if ([_currentAnswer length] >= _maxAnswerLength) { //Allow only entering of chars, when enough space remaining
			return;
		}
		
		//Alter answer
		NSUInteger len = [_currentAnswer length];
		if (len > 0) {
			_currentAnswer = [_currentAnswer stringByAppendingString:text];
		} else {
			_currentAnswer = text;
		}
		
		//Ensure visibility of next char
		if ([self isInputInHorizontalDirection]) {
			uint32_t nextCol = _startCellCol + (uint32_t) [_currentAnswer length];
			if (nextCol < [_savedCrossword width]) {
				[self ensureVisibleRow:_startCellRow col:nextCol];
			}
		} else {
			uint32_t nextRow = _startCellRow + (uint32_t) [_currentAnswer length];
			if (nextRow < [_savedCrossword height]) {
				[self ensureVisibleRow:nextRow col:_startCellCol];
			}
		}
	}
	
	//Fill grid
	[_crosswordView reloadData];
}

#pragma mark - UITextInputTraits protocol

- (UIKeyboardType)keyboardType {
	return UIKeyboardTypeASCIICapable;
}

- (UIKeyboardAppearance)keyboardAppearance {
	return UIKeyboardAppearanceDark;
}

- (UIReturnKeyType)returnKeyType {
	return UIReturnKeyDone;
}

- (BOOL)enablesReturnKeyAutomatically {
	return YES;
}

- (UITextAutocorrectionType)autocorrectionType {
	return UITextAutocorrectionTypeNo;
}

- (UITextSpellCheckingType)spellCheckingType {
	return UITextSpellCheckingTypeNo;
}

- (UITextSmartQuotesType)smartQuotesType {
	return UITextSmartQuotesTypeNo;
}

- (UITextSmartDashesType)smartDashesType {
	return UITextSmartDashesTypeNo;
}

- (UITextSmartInsertDeleteType)smartInsertDeleteType {
	return UITextSmartInsertDeleteTypeNo;
}

#pragma mark - Keyboard notifications

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillBeHidden:)
												 name:UIKeyboardWillHideNotification object:nil];
	
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
	[self commitValidAnswer];
	[self resetInput];
	[_crosswordView reloadData];
}

@end
