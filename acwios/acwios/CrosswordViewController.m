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
#import "EmitterEffect.h"
#import "NetLogger.h"
#import "GlossyButton.h"
#import "PackageManager.h"
#import "SubscriptionManager.h"

@interface CrosswordViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *crosswordView;
@property (weak, nonatomic) IBOutlet CrosswordLayout *crosswordLayout;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showHideButton;
@property (strong, nonatomic) IBOutlet UIPinchGestureRecognizer *pinchRecognizer;

@property (strong, nonatomic) IBOutlet UIView *helpView;
@property (strong, nonatomic) IBOutlet UIView *tapHelpView;

@property (weak, nonatomic) IBOutlet UIView *winView;
@property (weak, nonatomic) IBOutlet UIImageView *star1;
@property (weak, nonatomic) IBOutlet UIImageView *star2;
@property (weak, nonatomic) IBOutlet UIImageView *star3;
@property (weak, nonatomic) IBOutlet UILabel *winMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *winTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *winHintCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *winWordCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *winFailCountLabel;
@property (weak, nonatomic) IBOutlet GlossyButton *winCloseButton;

@end

@implementation CrosswordViewController {
	BOOL _areAnswersVisible;
	NSMutableDictionary<NSIndexPath*, NSString*> *_cellFilledValues; ///< The current fill state of the whole grid.
	
	//Show hide button repeat protection
	BOOL _showHidePressed;
	NSTimer *_showHideTimer;

	//Text input data
	BOOL _canBecameFirstResponder;
	NSString *_currentAnswer;
	uint32_t _maxAnswerLength;
	int32_t _startCellRow;
	int32_t _startCellCol;
	int32_t _answerIndex; ///< The rolling index of the current answer selected for input, when multiple answers are available in a start cell.
	NSMutableArray<NSNumber*> *_availableAnswerDirections; ///< All of the available input directions can be originated from the current start cell.
	
	//Statistics
	uint32_t _failCount;
	uint32_t _hintCount;
	NSDate* _startTime;
	BOOL _isFilled;
	
	//Win screen effects
	NSTimer *_timerWin;
	EmitterEffect *_emitterWin[4];
	NSUInteger _starCount;
}

#pragma mark - Implementation

-(void) showSubscription {
	__block UIViewController *parentVC = [self presentingViewController];
	[self dismissViewControllerAnimated:YES completion:^{
		[[SubscriptionManager sharedInstance] showSubscriptionAlert:parentVC
																msg:@"You have to subscribe to the application to play more than one demo crossword! If you press yes, then we take you to our store screen to do that."];
	}];
}

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
		BOOL answerCommitted = NO;
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
				//Send netlog
				if ([_cellFilledValues count] == 0) { //First word committed
					[NetLogger logEvent:@"Crossword_FirstFilled"];
				}
				
				//Copy values to grid
				for (NSUInteger i = 0; i < len; ++i) {
					NSString *val = [NSString stringWithFormat: @"%C", [_currentAnswer characterAtIndex:i]];
					NSIndexPath *path = [self getIndexPathForRow:_startCellRow col:_startCellCol + i];
					[_cellFilledValues setObject:val forKey:path];
				}
				
				//Save filled values
				[_savedCrossword saveFilledValues:_cellFilledValues];
				
				//Sign committed result
				answerCommitted = YES;
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
				//Send netlog
				if ([_cellFilledValues count] == 0) { //First word committed
					[NetLogger logEvent:@"Crossword_FirstFilled"];
				}

				//Copy values to grid
				for (NSUInteger i = 0; i < len; ++i) {
					NSString *val = [NSString stringWithFormat: @"%C", [_currentAnswer characterAtIndex:i]];
					NSIndexPath *path = [self getIndexPathForRow:_startCellRow + i col:_startCellCol];
					[_cellFilledValues setObject:val forKey:path];
				}
				
				//Save filled values
				[_savedCrossword saveFilledValues:_cellFilledValues];

				//Sign committed result
				answerCommitted = YES;
			}
		}
		
		if (answerCommitted) {
			//Determine filled state
			[self calculateFillRatio:&_isFilled];
			
			//Go to win, if all field filled
			if (_isFilled) {
				[self showWinScreen];
			}
		} else {
			++_failCount;
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

-(void) resetStatistics {
	_failCount = 0;
	_hintCount = 0;
	_startTime = [NSDate date];
	_isFilled = NO;
	_starCount = 0;
}

-(double) calculateFillRatio:(BOOL*)isFilled {
	uint32_t valueCellCount = 0;
	uint32_t filledCellCount = 0;
	
	for (uint32_t row = 0, rowEnd = (uint32_t) [_crosswordLayout rowCount]; row < rowEnd; ++row) {
		for (uint32_t col = 0, colEnd = (uint32_t) [_crosswordLayout columnCount]; col < colEnd; ++col) {
			uint32_t cellType = [_savedCrossword getCellTypeInRow:row col:col];
			if ((cellType & CWCellType_HasValue) != 0) {
				++valueCellCount;
				
				NSIndexPath *indexPath = [self getIndexPathForRow:row col:col];
				NSString *val = [_cellFilledValues objectForKey:indexPath];
				if ([val length] > 0) {
					++filledCellCount;
				}
			}
		}
	}

	double fillRatio = valueCellCount > 0 ? (double) filledCellCount / (double) valueCellCount : 1.0;
	*isFilled = filledCellCount == valueCellCount ? YES : NO;
	return *isFilled ? 1.0 : fillRatio;
}

-(void) mergeStatistics {
	BOOL isFilled = NO;
	double fillRatio = [self calculateFillRatio:&isFilled];
	[self saveStatistics:fillRatio isFilled:isFilled];
}

-(void) saveStatistics:(double)fillRatio isFilled:(BOOL)isFilled {
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:_startTime];
	[_savedCrossword mergeStatistics:_failCount hintCount:_hintCount fillRatio:fillRatio isFilled:isFilled fillDuration:duration];
	
	int32_t statOffset = [_savedCrossword loadStatisticsOffset];
	if (statOffset < 0) {
		NSArray<Statistics*> *stats = [_savedCrossword loadStatistics];
		
		NSString* packageKey = [_currentPackage getPackageKey];
		NSUInteger maxStatCount = [[PackageManager sharedInstance] getMaxStatCountOfCWSet:packageKey];
		int32_t statOffset = (int32_t) (maxStatCount - [stats count] - 1);
		if (statOffset < 0) {
			statOffset = 0;
		}
		
		[_savedCrossword saveStatisticsOffset:(uint32_t) statOffset];
	}
	
	[self resetStatistics];
}

-(NSUInteger)calculateStarCount:(Statistics*)stats {
	if (stats.failCount > 9 || stats.hintCount > 9 || stats.fillDuration > 20 * 60) { //0 star
		return 0;
	}

	if (stats.failCount > 6 || stats.hintCount > 6 || stats.fillDuration > 15 * 60) { //1 star
		return 1;
	}

	if (stats.failCount > 3 || stats.hintCount > 3 || stats.fillDuration > 12 * 60) { //2 star
		return 2;
	}

	return 3;
}

-(UIImage *)convertImageToGrayScale:(UIImage *)image {
	CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

	CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
	CGContextDrawImage(context, imageRect, [image CGImage]);
	CGImageRef imageRef = CGBitmapContextCreateImage(context);

	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	
	context = CGBitmapContextCreate(nil,image.size.width, image.size.height, 8, 0, nil, kCGImageAlphaOnly );
	CGContextDrawImage(context, imageRect, [image CGImage]);
	CGImageRef mask = CGBitmapContextCreateImage(context);
	
	UIImage *newImage = [UIImage imageWithCGImage:CGImageCreateWithMask(imageRef, mask)];
	
	CGImageRelease(imageRef);
	CGImageRelease(mask);
	CGContextRelease(context);
	
	// Return the new grayscale image
	return newImage;
}

-(void) showWinView {
	NSArray<Statistics*>* stats = [_savedCrossword loadStatistics];
	Statistics* currentStat = [stats lastObject];
	if (currentStat == nil) {
		return;
	}
	
	//Fill statistics view
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:currentStat.fillDuration];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH:mm:ss"];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	NSString *formattedDate = [dateFormatter stringFromDate:date];
	[self->_winTimeLabel setText:[NSString stringWithFormat:@"Time: %@", formattedDate]];
	
	[self->_winHintCountLabel setText:[NSString stringWithFormat:@"Hint show count: %d", currentStat.hintCount]];
	[self->_winWordCountLabel setText:[NSString stringWithFormat:@"Word count: %lu", [[self->_savedCrossword words] count]]];
	[self->_winFailCountLabel setText:[NSString stringWithFormat:@"Fail count: %d", currentStat.failCount]];
	
	//Show statistics view
	[self->_winView setHidden:NO];
	[[self->_winView layer] setCornerRadius:5];
	[[self->_winView layer] setMasksToBounds:YES];
	[[self->_winView layer] setBorderWidth:1];
	[[self->_winView layer] setBorderColor: [UIColor blackColor].CGColor];
	
	CGRect windowFrame = [[self view] bounds];
	CGPoint scrollPos = [self->_crosswordView contentOffset];
	CGFloat flX = (windowFrame.size.width - 300) / 2 + scrollPos.x;
	CGFloat flY = (windowFrame.size.height - 250) / 2 + scrollPos.y;
	[self->_winView setFrame:CGRectMake(flX, flY, 300, 280)];
	
	//Handle stars
	_starCount = [self calculateStarCount:currentStat];
	if (_starCount > 0) {
		[self->_star1 setImage:[UIImage imageNamed:@"star"]];
	} else {
		[self->_star1 setImage:[self convertImageToGrayScale:[UIImage imageNamed:@"star"]]];
	}
	
	if (_starCount > 1) {
		[self->_star2 setImage:[UIImage imageNamed:@"star"]];
	} else {
		[self->_star2 setImage:[self convertImageToGrayScale:[UIImage imageNamed:@"star"]]];
	}
	
	if (_starCount > 2) {
		[self->_star3 setImage:[UIImage imageNamed:@"star"]];
	} else {
		[self->_star3 setImage:[self convertImageToGrayScale:[UIImage imageNamed:@"star"]]];
	}
	
	//Handle multi level game
	if (_isMultiLevelGame) {
		if (_starCount < 3) { //Fail
			[self->_winMessageLabel setText:@"You can do this better!\nTry again!"];
			[self->_winCloseButton setTitle:@"Try again" forState:UIControlStateNormal];
		} else { //Go to the next level, or end of all levels
			BOOL isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
			if (isSubscribed && _currentPackage.state.filledLevel < _currentPackage.state.levelCount) {
				_currentPackage.state.filledLevel += 1;
				_currentPackage.state.filledWordCount += [[_savedCrossword words] count];
			}

			NSUInteger nextCWIdx = _currentCrosswordIndex + 1;
			BOOL hasMoreLevel = nextCWIdx < [_allSavedCrossword count];

			if (hasMoreLevel) {
				if (isSubscribed) {
					_currentPackage.state.crosswordName = [[_allSavedCrossword objectAtIndex:nextCWIdx] name];
				}

				[self->_winMessageLabel setText:@"You earn 3 stars!\nGo to the next level!"];
				[self->_winCloseButton setTitle:@"Next Level" forState:UIControlStateNormal];
			} else {
				[self->_winMessageLabel setText:@"You filled all levels!"];
				[self->_winCloseButton setTitle:@"OK" forState:UIControlStateNormal];
			}
			
			if (isSubscribed) {
				[[PackageManager sharedInstance] savePackageState:_currentPackage];
			}
		}
	} else { //Single level game
		if (_starCount < 3) {
			[self->_winMessageLabel setText:@"You can do this better!\nTry again!"];
			[self->_winCloseButton setTitle:@"Try again" forState:UIControlStateNormal];
		} else {
			[self->_winMessageLabel setText:@"You earn 3 stars!"];
			[self->_winCloseButton setTitle:@"OK" forState:UIControlStateNormal];
		}
	}
	
	[self->_crosswordView addSubview:self->_winView];
}

-(void) showWinScreen {
	[self resetInput];
	
	[self->_crosswordView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
								 atScrollPosition:UICollectionViewScrollPositionTop | UICollectionViewScrollPositionLeft
										 animated:NO];

	//Save statistics
	[self saveStatistics:1.0 isFilled:YES];
	
	//Send netlog
	[NetLogger logEvent:@"Crossword_Win"];
	
	//Start emitters
	CGRect frame = [[self view] frame];
	__block CGSize size = CGSizeMake (frame.size.width / 2.0 * 0.8, 2.0 * frame.size.height / 3.0 * 0.8);

	__block CGPoint ptStart0 = CGPointMake (frame.origin.x + frame.size.width * 0.1, frame.origin.y + frame.size.height);
	_emitterWin[0] = [[EmitterEffect alloc] init];
	[_emitterWin[0] startFire:[self view] pt:ptStart0];

	__block CGPoint ptStart1 = CGPointMake (frame.origin.x + frame.size.width * 0.9, frame.origin.y + frame.size.height);
	_emitterWin[1] = [[EmitterEffect alloc] init];
	[_emitterWin[1] startFire:[self view] pt:ptStart1];

	_emitterWin[2] = [[EmitterEffect alloc] init];
	_emitterWin[3] = [[EmitterEffect alloc] init];
	
	__block NSDate* start = nil;
	_timerWin = [NSTimer scheduledTimerWithTimeInterval:0.05
												repeats:YES
												  block:^(NSTimer * _Nonnull timer)
	{
		const CGFloat duration = 2.0;
		if (start == nil) {
			start = [NSDate date];
		}
		
		NSTimeInterval dT = [[NSDate date] timeIntervalSinceDate:start]; //Elapsed time: [sec]

		//The function of the fireball is: y=x*x
		const CGFloat velocity = 100.0; //velocity: [dx / sec]
		const CGFloat maxX = duration * velocity;
		const CGFloat maxY = maxX * maxX;
		
		CGFloat xPos = velocity * (duration - dT);
		CGFloat yPos = xPos * xPos;
		xPos /= maxX;
		yPos /= maxY;
		
		xPos = 1.0 - xPos;
		yPos = 1.0 - yPos;
		
//		NSLog (@"xPos: %.3f, yPos: %.3f", xPos, yPos);
		
		CGPoint pt0 = CGPointMake (ptStart0.x + xPos * size.width, ptStart0.y - yPos * size.height);
		CGPoint pt1 = CGPointMake (ptStart1.x - xPos * size.width, ptStart1.y - yPos * size.height);
//		NSLog (@"ptF: %@, ptS: %@", NSStringFromCGPoint (pt0), NSStringFromCGPoint (pt1));
		
		[self->_emitterWin[0] moveTo:pt0];
		[self->_emitterWin[1] moveTo:pt1];

		//End of animation
		if (dT >= duration * 1.005) {
			[self->_emitterWin[0] stop];
			[self->_emitterWin[1] stop];
			
			[self->_emitterWin[2] startFireWorks:[self view] pt:pt0];
			[self->_emitterWin[3] startFireWorks:[self view] pt:pt1];
			
			[self->_timerWin invalidate];
			
			[self showWinView];
		}
	}];
}

-(void) showHelpScreen {
	[_helpView removeFromSuperview];
	
	[self->_helpView setHidden:NO];
	[[self->_helpView layer] setCornerRadius:5];
	[[self->_helpView layer] setMasksToBounds:YES];
	[[self->_helpView layer] setBorderWidth:1];
	[[self->_helpView layer] setBorderColor: [UIColor blackColor].CGColor];
	
	CGFloat fMargin = 4;
	CGFloat fNavHeight = self.navigationController.navigationBar.frame.size.height;

	[[self view] addSubview:self->_helpView];
	
	self->_helpView.translatesAutoresizingMaskIntoConstraints = NO;
	
	NSLayoutConstraint *trailing = [NSLayoutConstraint
									constraintWithItem:self->_helpView
									attribute:NSLayoutAttributeTrailing
									relatedBy:NSLayoutRelationEqual
									toItem:[self view]
									attribute:NSLayoutAttributeTrailing
									multiplier:1.0f
									constant:-fMargin];
	
	NSLayoutConstraint *top = [NSLayoutConstraint
							   constraintWithItem:self->_helpView
							   attribute:NSLayoutAttributeTop
							   relatedBy:NSLayoutRelationEqual
							   toItem:[self view]
							   attribute:NSLayoutAttributeTop
							   multiplier:1.0f
							   constant:fMargin + fNavHeight];
	
	//Add constraints to the Parent
	[[self view] addConstraint:trailing];
	[[self view] addConstraint:top];
}

- (void) showTapHelpScreen {
	[_tapHelpView removeFromSuperview];
	
	[self->_tapHelpView setHidden:NO];
	[[self->_tapHelpView layer] setCornerRadius:5];
	[[self->_tapHelpView layer] setMasksToBounds:YES];
	[[self->_tapHelpView layer] setBorderWidth:1];
	[[self->_tapHelpView layer] setBorderColor: [UIColor blackColor].CGColor];
	
	CGFloat fMargin = 4;
	CGFloat fNavHeight = self.navigationController.navigationBar.frame.size.height;
	CGFloat fCellHeight = _crosswordLayout.cellHeight;
	CGFloat fCellWidth = _crosswordLayout.cellWidth;
	
	[[self view] addSubview:self->_tapHelpView];
	
	self->_tapHelpView.translatesAutoresizingMaskIntoConstraints = NO;
	
	NSLayoutConstraint *leading = [NSLayoutConstraint
								   constraintWithItem:self->_tapHelpView
								   attribute:NSLayoutAttributeLeading
								   relatedBy:NSLayoutRelationEqual
								   toItem:[self view]
								   attribute:NSLayoutAttributeLeading
								   multiplier:1.0f
								   constant:fMargin + fCellWidth / 3.0];
	
	NSLayoutConstraint *top = [NSLayoutConstraint
							   constraintWithItem:self->_tapHelpView
							   attribute:NSLayoutAttributeTop
							   relatedBy:NSLayoutRelationEqual
							   toItem:[self view]
							   attribute:NSLayoutAttributeTop
							   multiplier:1.0f
							   constant:fMargin + fNavHeight + 4.0 * fCellHeight / 3.0];
	
	//Add constraints to the Parent
	[[self view] addConstraint:leading];
	[[self view] addConstraint:top];
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[NetLogger logEvent:@"Crossword_ShowView" withParameters:@{ @"package" : [_savedCrossword packageName],
																@"name" : [_savedCrossword name] }];
	
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //[self.collectionView registerClass:[CrosswordCell class] forCellWithReuseIdentifier:cellReusableIdentifier];
	
    // Do any additional setup after loading the view.
	_areAnswersVisible = NO;
	_showHidePressed = NO;
	_cellFilledValues = [NSMutableDictionary<NSIndexPath*, NSString*> new];
	[_savedCrossword loadFilledValuesInto:_cellFilledValues];

	[self resetInput];
	[self registerForKeyboardNotifications];
	
	[_crosswordLayout setScaleFactor:1];
	[_crosswordLayout setCellWidth:50];
	[_crosswordLayout setCellHeight:50];
	[_crosswordLayout setRowCount:[_savedCrossword height]];
	[_crosswordLayout setColumnCount:[_savedCrossword width]];
	[_crosswordLayout setStatusBarHeight:[UIApplication sharedApplication].statusBarFrame.size.height];
	[_crosswordLayout setNavigationBarHeight:self.navigationController.navigationBar.frame.size.height];
	
	[_savedCrossword loadDB];
	
	_inputViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"KeyboardVC"];
	KeyboardViewController* kbVC = (KeyboardViewController*) _inputViewController;
	[kbVC setUsedKeys:[_savedCrossword getUsedKeys]];
	[kbVC setup];
	
	[self resetStatistics];
	
	[self.collectionView addGestureRecognizer:_pinchRecognizer];
	
	if (_currentPackage.state.wasHelpShown == NO) {
		[self showHelpScreen];

		_currentPackage.state.wasHelpShown = YES;
		[[PackageManager sharedInstance] savePackageState:_currentPackage];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
	[self mergeStatistics];
	[_savedCrossword unloadDB];
	[self dismissViewControllerAnimated:YES completion:nil];
	
	//Send netlog
	[NetLogger logEvent:@"Crossword_BackPressed"];
}

- (IBAction)showHideButtonPressed:(id)sender {
	if (_showHidePressed) {
		return;
	}
	_showHidePressed = YES;
	
	_areAnswersVisible = _areAnswersVisible ? NO : YES;
	[_showHideButton setTitle:_areAnswersVisible ? @"Hide Hint" : @"Show Hint"];
	[_crosswordView reloadData];
	
	if (_areAnswersVisible) {
		++_hintCount;
		
		//Send netlog
		[NetLogger logEvent:@"Crossword_HintShow"];
	}
	
	_showHideTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
												repeats:NO
												  block:^(NSTimer * _Nonnull timer)
	{
		self->_showHidePressed = NO;
		[self->_showHideTimer invalidate];
	}];
}

- (IBAction)resetButtonPressed:(id)sender {
	[_cellFilledValues removeAllObjects];
	[_savedCrossword saveFilledValues:_cellFilledValues];
	[_crosswordView reloadData];
	
	//Reset statistics
	[self resetStatistics];
	[_savedCrossword resetStatistics];
	
	//Send netlog
	[NetLogger logEvent:@"Crossword_ResetPressed"];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	__block BOOL winViewHidden = [_winView isHidden];
	__block BOOL helpViewHidden = [_helpView isHidden];
	__block BOOL tapHelpViewHidden = [_tapHelpView isHidden];
	[_winView setHidden:YES];
	[_helpView setHidden:YES];
	[_tapHelpView setHidden:YES];
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		//Nothing to do...
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		if (!winViewHidden) {
			[self showWinView];
		}
		
		if (!helpViewHidden) {
			[self showHelpScreen];
		}
		
		if (!tapHelpViewHidden) {
			[self showTapHelpScreen];
		}
	}];
}

- (IBAction)congratsButtonPressed:(id)sender {
	NSUInteger starCount = _starCount;
	[self resetButtonPressed:sender];
	
	[_winView setHidden:YES];

	if (starCount < 3) { //Failed
		return; //Fill again
	}
	
	[_savedCrossword unloadDB];
	if (_isMultiLevelGame) {
		NSUInteger nextCWIdx = _currentCrosswordIndex + 1;
		BOOL hasMoreLevel = nextCWIdx < [_allSavedCrossword count];
		
		if (hasMoreLevel) { //We have more level available
			//Check subscription
			BOOL isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
			if (isSubscribed) { //Go to the next level
				[self performSegueWithIdentifier:@"ShowCW" sender:self];
			} else { //Show store alert
				[self showSubscription];
			}
		} else { //No more level
			[self dismissViewControllerAnimated:YES completion:nil];
		}
	} else { //Single level game
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)sender {
	if ([sender numberOfTouches] != 2) {
		return;
	}
	
	CGFloat scale = sender.scale * [_crosswordLayout scaleFactor];
	sender.scale = 1.0;
	
	if (scale < 1.0) {
		scale = 1.0;
	} else if (scale > 5) {
		scale = 5;
	}
	
	[_crosswordLayout setScaleFactor: scale];
	[_crosswordView reloadData];
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	
	[_helpView setHidden:YES];
	
	if (_currentPackage.state.wasTapHelpShown == NO) {
		[self showTapHelpScreen];
		
		_currentPackage.state.wasTapHelpShown = YES;
		[[PackageManager sharedInstance] savePackageState:_currentPackage];
	} else {
		[_tapHelpView setHidden:YES];
	}
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowCW"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[UINavigationController class]])
	{
		UINavigationController *navController = (UINavigationController*) [segue destinationViewController];
		if ([[navController topViewController] isKindOfClass:[CrosswordViewController class]]) {
			CrosswordViewController *cwController = (CrosswordViewController*) [navController topViewController];
			NSUInteger nextCWIdx = _currentCrosswordIndex + 1;
			SavedCrossword *nextCW = [_allSavedCrossword objectAtIndex:nextCWIdx];
			
			[cwController setCurrentPackage:_currentPackage];
			[cwController setSavedCrossword:nextCW];
			[cwController setCurrentCrosswordIndex:nextCWIdx];
			[cwController setAllSavedCrossword:_allSavedCrossword];
			[cwController setIsMultiLevelGame:YES];
		}
	}
}

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

-(BOOL)isAplhaNumericValue:(NSString*)value {
	NSCharacterSet *charSet = [NSCharacterSet alphanumericCharacterSet];
	NSRange r = [value rangeOfCharacterFromSet:charSet];
	return r.location != NSNotFound;
}

-(void) fillLetterForCell:(CrosswordCell*)cell row:(uint32_t)row col:(uint32_t)col highlighted:(BOOL)highlighted currentCell:(BOOL)currentCell {
	BOOL fillValue = NO;
	NSString* cellOrigValue = [_savedCrossword getCellsValue:row col:col];
	NSString* cellValue;
	if (_areAnswersVisible || ![self isAplhaNumericValue:cellOrigValue]) {
		fillValue = YES;
		cellValue = cellOrigValue;
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
	
	[cell fillLetter:fillValue value:cellValue highlighted:highlighted currentCell:currentCell scale:[_crosswordLayout scaleFactor]];
}

-(void) fillCellsArrow:(uint32_t)cellType
		 checkCellType:(enum CWCellType)checkCellType
				  cell:(CrosswordCell*)cell
				   row:(uint32_t)row
				   col:(uint32_t)col
		   highlighted:(BOOL)highlighted
		   currentCell:(BOOL)currentCell
		  letterFilled:(BOOL*)letterFilled
{
	if (cellType & checkCellType) {
		if (*letterFilled != YES) {
			[self fillLetterForCell:cell row:row col:col highlighted:highlighted currentCell:currentCell];
			*letterFilled = YES;
		}
		[cell fillArrow:checkCellType scale:[_crosswordLayout scaleFactor]];
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
		
		BOOL isHighlighted = NO;
		BOOL isCurrentCell = NO;
		if (_answerIndex >= 0) {
			if ([self isInputInHorizontalDirection]) {
				isHighlighted = row == _startCellRow && col >= _startCellCol && col < _startCellCol + _maxAnswerLength ? YES : NO;
				isCurrentCell = row == _startCellRow && col == _startCellCol + [_currentAnswer length];
			} else {
				isHighlighted = col == _startCellCol && row >= _startCellRow && row < _startCellRow + _maxAnswerLength ? YES : NO;
				isCurrentCell = col == _startCellCol && row == _startCellRow + [_currentAnswer length];
			}
		}
		
		switch (cellType) {
			case CWCellType_SingleQuestion:
				[cell fillOneQuestion:[_savedCrossword getCellsQuestion:row col:col questionIndex:0] scale:[_crosswordLayout scaleFactor]];
				break;
			case CWCellType_DoubleQuestion: {
				NSString* qTop = [_savedCrossword getCellsQuestion:row col:col questionIndex:0];
				NSString* qBottom = [_savedCrossword getCellsQuestion:row col:col questionIndex:1];
				[cell fillTwoQuestion:qTop questionBottom:qBottom scale:[_crosswordLayout scaleFactor]];
				break;
			}
			case CWCellType_Spacer:
				[cell fillSpacer];
				break;
			case CWCellType_Letter:
				[self fillLetterForCell:cell row:row col:col highlighted:isHighlighted currentCell:isCurrentCell];
				[cell fillSeparator:[_savedCrossword getCellsSeparators:row col:col] scale:[_crosswordLayout scaleFactor]];
				break;
			default: {
				BOOL letterFilled = NO;
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Right cell:cell row:row col:col highlighted:isHighlighted
						 currentCell:isCurrentCell letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Left cell:cell row:row col:col highlighted:isHighlighted
						 currentCell:isCurrentCell letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopDown_Bottom cell:cell row:row col:col highlighted:isHighlighted
						 currentCell:isCurrentCell letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_TopRight cell:cell row:row col:col highlighted:isHighlighted
						 currentCell:isCurrentCell letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_FullRight cell:cell row:row col:col highlighted:isHighlighted
						 currentCell:isCurrentCell letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_BottomRight cell:cell row:row col:col highlighted:isHighlighted
						 currentCell:isCurrentCell letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_LeftRight_Top cell:cell row:row col:col highlighted:isHighlighted
						 currentCell:isCurrentCell letterFilled:&letterFilled];
				[self fillCellsArrow:cellType checkCellType:CWCellType_Start_LeftRight_Bottom cell:cell row:row col:col highlighted:isHighlighted
						 currentCell:isCurrentCell letterFilled:&letterFilled];
				[cell fillSeparator:[_savedCrossword getCellsSeparators:row col:col] scale:[_crosswordLayout scaleFactor]];
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
	
	//Add next non alphanumeric char automatically
	if (isNewStart) {
		NSString *nextVal = [_savedCrossword getCellsValue:_startCellRow col:_startCellCol];
		if (![self isAplhaNumericValue:nextVal]) {
			[self insertText:nextVal];
		}
	}

	//Highlight the word have to be enter
	[_crosswordView reloadData];
	
	//TEST
//	[self showWinScreen];
	//END TEST
}

#pragma mark - UICollectionViewDelegate

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	[_helpView setHidden:YES];
	
	if (_currentPackage.state.wasTapHelpShown == NO) {
		[self showTapHelpScreen];
		
		_currentPackage.state.wasTapHelpShown = YES;
		[[PackageManager sharedInstance] savePackageState:_currentPackage];
		return NO;
	} else {
		[_tapHelpView setHidden:YES];
	}
	
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
		
		//Calculate next cell's coords
		BOOL isHorizontalInput = [self isInputInHorizontalDirection];
		uint32_t nextCol = 0;
		uint32_t nextRow = 0;
		if (isHorizontalInput) {
			nextRow = _startCellRow;
			nextCol = _startCellCol + (uint32_t) [_currentAnswer length];
		} else {
			nextRow = _startCellRow + (uint32_t) [_currentAnswer length];
			nextCol = _startCellCol;
		}
		
		//Ensure visibility of next char
		if (isHorizontalInput) {
			if (nextCol < [_savedCrossword width]) {
				[self ensureVisibleRow:_startCellRow col:nextCol];
			}
		} else {
			if (nextRow < [_savedCrossword height]) {
				[self ensureVisibleRow:nextRow col:_startCellCol];
			}
		}
		
		//Add next non alphanumeric char automatically
		NSString *nextVal = [_savedCrossword getCellsValue:nextRow col:nextCol];
		if (![self isAplhaNumericValue:nextVal]) {
			[self insertText:nextVal];
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
