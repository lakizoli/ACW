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
	id<KeyboardConfig> _keyboardConfig;
	
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
	[self createPage:PAGE_ALPHA];
}

#pragma mark - Setup buttons

-(void) createPage:(uint32_t)page {
	NSArray<NSString*>* keys = nil;
	NSArray<NSNumber*>* weights = nil;
	for (uint32_t row = 0; row < 4; ++row) {
		if ([_keyboardConfig rowKeys:row page:page outKeys:&keys outWieghts:&weights] == YES) {
			[self createButtonsForKeys:keys
								widths:weights
						   destination:[_rowViews objectAtIndex:row]
						 buttonStorage:_rowButtons[row]
					 constraintStorage:_constraints[row]];
		}
	}
}

- (void) createButtonsForKeys:(NSArray<NSString*>*)keys
					   widths:(NSArray<NSNumber*>*)widths
				  destination:(UIStackView*)destination
				buttonStorage:(NSMutableArray<UIButton*>*)buttonStorage
			constraintStorage:(NSMutableArray<NSLayoutConstraint*>*)constraintStorage
{
	__block CGFloat sumWidth = 0;
	[widths enumerateObjectsUsingBlock:^(NSNumber * _Nonnull val, NSUInteger idx, BOOL * _Nonnull stop) {
		sumWidth += [val floatValue];
	}];
	
	[buttonStorage removeAllObjects];
	[constraintStorage removeAllObjects];
	
	[keys enumerateObjectsUsingBlock:^(NSString * _Nonnull keyValue, NSUInteger idx, BOOL * _Nonnull stop) {
		//Create button
		GlossyButton *button = [[GlossyButton alloc] initWithFrame:CGRectMake (0, 0, 0, 0)];
		[buttonStorage addObject:button];

		//TODO: handle special key values (with images or so)...
		[button setTitle:keyValue forState:UIControlStateNormal];
		[self setupButtonsAction:button keyValue:keyValue];
		
		//Add button to the stack view
		[destination addArrangedSubview:button];

		//Add constraint
		CGFloat widthRatio = [[widths objectAtIndex:idx] floatValue] / sumWidth;
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

-(void) setupButtonsAction:(UIButton*)button keyValue:(NSString*)keyValue {
	if ([keyValue caseInsensitiveCompare:BACKSPACE] == NSOrderedSame) {
		[button addTarget:self action:@selector (backSpacePressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([keyValue caseInsensitiveCompare:ENTER] == NSOrderedSame) {
		[button addTarget:self action:@selector (enterPressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([keyValue caseInsensitiveCompare:SPACEBAR] == NSOrderedSame) {
		[button addTarget:self action:@selector (spacePressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([keyValue caseInsensitiveCompare:TURNOFF] == NSOrderedSame) {
		[button addTarget:self action:@selector (turnOffPressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([keyValue caseInsensitiveCompare:SWITCHNUM] == NSOrderedSame) {
		[button addTarget:self action:@selector (switchNumPressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([keyValue caseInsensitiveCompare:SWITCHALPHA] == NSOrderedSame) {
		[button addTarget:self action:@selector (switchAlphaPressed) forControlEvents:UIControlEventTouchUpInside];
	} else if ([keyValue hasPrefix:@"Ex"]) { //Extra key
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

-(NSSet<NSString*>*) getKeyboardKeys:(id<KeyboardConfig>)keyboardConfig {
	__block NSMutableSet<NSString*>* res = [NSMutableSet<NSString*> new];
	
	for (uint32_t page = 0;page < 2;++page) {
		for (uint32_t row = 0;row < 4;++row) {
			NSArray<NSString*>* keys = nil;
			NSArray<NSNumber*>* weights = nil;
			if ([keyboardConfig rowKeys:row page:page outKeys:&keys outWieghts:&weights] == YES) {
				[keys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
					[res addObject:obj];
				}];
			}
		}
	}
	
	return res;
}

-(uint32_t) getNotFoundKeyCount:(id<KeyboardConfig>)keyboardConfig {
	__block uint32_t notFoundCount = 0;
	
	__block NSSet<NSString*> *keys = [self getKeyboardKeys:keyboardConfig];
	[_usedKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		if ([keys containsObject:[obj uppercaseString]] != YES) {
			++notFoundCount;
		}
	}];
	
	return notFoundCount;
}

//-(NSSet<NSString*>*) collectExtraKeys:(id<KeyboardConfig>*)keyboardConfig {
//	//TODO: implement countOfKeysFoundOnKeyboard
//	return 0;
//}

-(id<KeyboardConfig>)chooseBestFitKeyboard {
	//TODO: choose best fit keyboard for the results!
	//TODO: collect extra characters for available extra keys!

	id<KeyboardConfig> cfg = [[USKeyboard alloc] init];
	
	uint32_t notFoundKeyCount = [self getNotFoundKeyCount:cfg];
	if (notFoundKeyCount <= 0) {
		return cfg;
//	} else if (notFoundKeyCount <= /*extra key count*/) {
		//TODO: ...
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

-(void) switchNumPressed {
	[self removeAllButtons];
	[self createPage:PAGE_NUM];
}

-(void) switchAlphaPressed {
	[self removeAllButtons];
	[self createPage:PAGE_ALPHA];
}

-(void) extraKeyPressed:(id)sender {
	if ([sender isKindOfClass:[UIButton class]]) {
//		UIButton *button = (UIButton*) sender;
//		NSString *key = [[button titleLabel] text];
//		[[self textDocumentProxy] insertText:key];
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
