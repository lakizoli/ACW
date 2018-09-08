//
//  KeyboardViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 06..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "KeyboardViewController.h"
#import "GlossyButton.h"
#import "KeyboardConfigs.h"

@interface KeyboardViewController ()

@property (weak, nonatomic) IBOutlet UIStackView *firstKeyRow;
@property (weak, nonatomic) IBOutlet UIStackView *secondKeyRow;
@property (weak, nonatomic) IBOutlet UIStackView *thirdKeyRow;
@property (weak, nonatomic) IBOutlet UIStackView *fourthKeyRow;

@end

@implementation KeyboardViewController {
	KeyboardConfig *_keyboardConfig;
	NSUInteger _currentPage;
	
	NSMutableArray<UIStackView*> *_rowViews;
	NSMutableArray<UIButton*> *_rowButtons[4];
	NSMutableArray<NSLayoutConstraint*> *_constraints[4];
}

#pragma mark - Event handling

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void) awakeFromNib {
	[super awakeFromNib];
	
	//Custom initialization
	self.view.translatesAutoresizingMaskIntoConstraints = false;
	
	_currentPage = PAGE_ALPHA;
	
	_rowViews = [NSMutableArray<UIStackView*> new];
	[_rowViews addObject:_firstKeyRow];
	[_rowViews addObject:_secondKeyRow];
	[_rowViews addObject:_thirdKeyRow];
	[_rowViews addObject:_fourthKeyRow];
	
	for (uint32_t row = 0; row < 4; ++row) {
		_rowButtons[row] = [NSMutableArray<UIButton*> new];
		_constraints[row] = [NSMutableArray<NSLayoutConstraint*> new];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Interface

-(void) setup {
	_keyboardConfig = [self chooseBestFitKeyboard];
	[self createPage:_currentPage];
}

#pragma mark - Setup buttons

-(void) createPage:(NSUInteger)page {
	NSArray<NSString*>* keys = nil;
	NSArray<NSNumber*>* weights = nil;
	for (NSUInteger row = 0; row < 4; ++row) {
		if ([_keyboardConfig rowKeys:row page:page outKeys:&keys outWeights:&weights] == YES) {
			[self createButtonsForKeys:keys
							   weights:weights
						   destination:[_rowViews objectAtIndex:row]
						 buttonStorage:_rowButtons[row]
					 constraintStorage:_constraints[row]];
		}
	}
}

- (void) createButtonsForKeys:(NSArray<NSString*>*)keys
					  weights:(NSArray<NSNumber*>*)weights
				  destination:(UIStackView*)destination
				buttonStorage:(NSMutableArray<UIButton*>*)buttonStorage
			constraintStorage:(NSMutableArray<NSLayoutConstraint*>*)constraintStorage
{
	__block CGFloat sumWeight = 0;
	[weights enumerateObjectsUsingBlock:^(NSNumber * _Nonnull val, NSUInteger idx, BOOL * _Nonnull stop) {
		sumWeight += [val floatValue];
	}];
	
	[buttonStorage removeAllObjects];
	[constraintStorage removeAllObjects];
	
	[keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
		//Create button
		GlossyButton *button = [[GlossyButton alloc] initWithFrame:CGRectMake (0, 0, 0, 0)];

		if ([key caseInsensitiveCompare:BACKSPACE] == NSOrderedSame) {
			//TODO: add image for backspace...
			[button setTitle:BACKSPACE forState:UIControlStateNormal];
		} else if ([key caseInsensitiveCompare:ENTER] == NSOrderedSame) {
			//TODO: alter enter button's color...
			[button setTitle:@"Done" forState:UIControlStateNormal];
		} else if ([key caseInsensitiveCompare:SPACEBAR] == NSOrderedSame) {
			[button setTitle:@"Space" forState:UIControlStateNormal];
		} else if ([key caseInsensitiveCompare:TURNOFF] == NSOrderedSame) {
			//TODO: add image for turn off...
			[button setTitle:TURNOFF forState:UIControlStateNormal];
		} else if ([key caseInsensitiveCompare:SWITCH] == NSOrderedSame) {
			//TODO: add image for switch...
			[button setTitle:SWITCH forState:UIControlStateNormal];
		} else if ([key hasPrefix:@"Ex"]) { //Extra key
			NSInteger extraKeyID = [self->_keyboardConfig getExtraKeyID:key page:self->_currentPage];
			if (extraKeyID > 0) { //Used extra key
				[button setTag:extraKeyID];
				
				NSString *title = [self->_keyboardConfig getTitleForExtraKeyID:extraKeyID];
				if (title) {
					[button setTitle:title forState:UIControlStateNormal];
				}
			} else { //Unused extra key
				[button setHidden:YES];
				[button setEnabled:NO];
			}
		} else { //Normal value key
			[button setTitle:key forState:UIControlStateNormal];
		}

		[buttonStorage addObject:button];
		[self setupButtonsAction:button key:key];
		
		//Add button to the stack view
		[destination addArrangedSubview:button];

		//Add constraint
		CGFloat widthRatio = [[weights objectAtIndex:idx] floatValue] / sumWeight;
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:button
																	  attribute:NSLayoutAttributeWidth
																	  relatedBy:NSLayoutRelationEqual
																		 toItem:destination
																	  attribute:NSLayoutAttributeWidth
																	 multiplier:widthRatio
																	   constant:0];
		[constraintStorage addObject:constraint];
		[destination addConstraint:constraint];
	}];
}

-(void) setupButtonsAction:(UIButton*)button key:(NSString*)key {
	if ([key caseInsensitiveCompare:BACKSPACE] == NSOrderedSame) {
		[button addTarget:self action:@selector (backSpacePressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([key caseInsensitiveCompare:ENTER] == NSOrderedSame) {
		[button addTarget:self action:@selector (enterPressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([key caseInsensitiveCompare:SPACEBAR] == NSOrderedSame) {
		[button addTarget:self action:@selector (spacePressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([key caseInsensitiveCompare:TURNOFF] == NSOrderedSame) {
		[button addTarget:self action:@selector (turnOffPressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([key caseInsensitiveCompare:SWITCH] == NSOrderedSame) {
		[button addTarget:self action:@selector (switchPressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([key hasPrefix:@"Ex"]) { //Extra key
		[button addTarget:self action:@selector (extraKeyPressed:) forControlEvents:UIControlEventTouchUpInside];
	} else { //Normal value key
		[button addTarget:self action:@selector (keyPressed:) forControlEvents:UIControlEventTouchUpInside];
	}
}

-(void) removeAllButtons {
	for (__block uint32_t row = 0; row < 4; ++row) {
		//Remove constraints from stack view
		[[_rowViews objectAtIndex:row] removeConstraints:_constraints[row]];
		[_constraints[row] removeAllObjects];
		
		//Remove buttons from stack view
		[_rowButtons[row] enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj removeFromSuperview];
		}];
		[_rowButtons[row] removeAllObjects];
	}
}

-(KeyboardConfig*)chooseBestFitKeyboard {
	//TODO: collect extra characters for available extra keys!
	
	NSArray<Class> *keyboardClasses = @[ [USKeyboard class] ]; //TODO: add other keyboard classes
	
	__block KeyboardConfig *cfg = nil;
	__block NSSet<NSString*> *extraKeys = nil;
	__block NSUInteger extraKeyCount = NSUIntegerMax;

	[keyboardClasses enumerateObjectsUsingBlock:^(Class  _Nonnull cls, NSUInteger idx, BOOL * _Nonnull stop) {
		KeyboardConfig *kb = [[USKeyboard alloc] init];
		
		NSSet<NSString*> *kbExtraKeys = [kb collectExtraKeys:self->_usedKeys];
		NSUInteger kbExtraKeyCount = [kbExtraKeys count];
		if (kbExtraKeyCount <= 0) { //We found a full keyboard without needing any extra keys
			cfg = kb;
			extraKeys = kbExtraKeys;
			extraKeyCount = kbExtraKeyCount;
			
			*stop = YES;
		} else if (kbExtraKeyCount < extraKeyCount) { //We found a keyboard config with lower extra button needs
			cfg = kb;
			extraKeys = kbExtraKeys;
			extraKeyCount = kbExtraKeyCount;
		}
	}];
	
	if (extraKeyCount > 0) {
		[cfg addExtraPages:extraKeys];
	}
	
	return cfg;
}

#pragma mark - Key events

-(void) backSpacePressed {
	[[self textDocumentProxy] deleteBackward];
}

-(void) enterPressed {
	[[self textDocumentProxy] insertText:@"\n"];
}

-(void) spacePressed {
	[[self textDocumentProxy] insertText:@" "];
}

-(void) turnOffPressed {
	[self dismissKeyboard];
}

-(void) switchPressed {
	[self removeAllButtons];
	
	++_currentPage;
	if (_currentPage >= [_keyboardConfig getPageCount]) {
		_currentPage = 0;
	}
	
	[self createPage:_currentPage];
}

-(void) extraKeyPressed:(id)sender {
	if ([sender isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton*) sender;
		NSInteger extraKeyID = [button tag];
		if (extraKeyID > 0) {
			NSString *value = [_keyboardConfig getValueForExtraKeyID:extraKeyID];
			if (value) {
				[[self textDocumentProxy] insertText:value];
			}
		}
	}
}

-(void) keyPressed:(id)sender {
	if ([sender isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton*) sender;
		NSString *key = [[button titleLabel] text];
		[[self textDocumentProxy] insertText:key];
	}
}

@end
