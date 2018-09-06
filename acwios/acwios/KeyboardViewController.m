//
//  KeyboardViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 06..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "KeyboardViewController.h"
#import "GlossyButton.h"

//Extra keys on keyboard
#define BACKSPACE	@"BackSpace"
#define ENTER		@"Done"
#define SPACEBAR	@"Space"
#define TURNOFF		@"TurnOff"

@interface KeyboardViewController ()

@property (weak, nonatomic) IBOutlet UIStackView *firstKeyRow;
@property (weak, nonatomic) IBOutlet UIStackView *secondKeyRow;
@property (weak, nonatomic) IBOutlet UIStackView *thirdKeyRow;
@property (weak, nonatomic) IBOutlet UIStackView *fourthKeyRow;

@end

@implementation KeyboardViewController

#pragma mark - Event handling

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void) awakeFromNib {
	[super awakeFromNib];
	
	//Custom initialization
	self.view.translatesAutoresizingMaskIntoConstraints = false;
	
	//TODO: choose best fit keyboard for the results!
	//TODO: collect extra characters for available extra keys!
	
	//US keyboard (for test now)
	[self createButtonsForKeys:@[@"Q", @"W", @"E", @"R", @"T", @"Y", @"U", @"I", @"O", @"P", @"Ex1", @"Ex2", BACKSPACE]
						widths:@[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,   @1.0,   @1.0,      @2.0]
				   destination:_firstKeyRow];
	
	[self createButtonsForKeys:@[@"A", @"S", @"D", @"F", @"G", @"H", @"J", @"K", @"L", @"Ex1", @"Ex2", @"Ex3", ENTER]
						widths:@[@1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,   @1.0,   @1.0,   @1.0,  @2.0]
				   destination:_secondKeyRow];
	
	[self createButtonsForKeys:@[@"Ex1", @"Ex2", @"Z", @"X", @"C", @"V", @"B", @"N", @"M", @"Ex3", @"Ex4", @"Ex5", @"Ex6"]
						widths:@[  @3.0,   @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0, @1.0,   @1.0,   @1.0,   @1.0,   @3.0]
				   destination:_thirdKeyRow];
	
	[self createButtonsForKeys:@[@"Ex1", @"Ex2", SPACEBAR, @"Ex3", TURNOFF]
						widths:@[  @1.0,   @1.0,     @3.0,   @1.0,    @1.0]
				   destination:_fourthKeyRow];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Create buttons

- (void) createButtonsForKeys:(NSArray<NSString*>*)keys widths:(NSArray<NSNumber*>*)widths destination:(UIStackView*)destination {
	__block CGFloat sumWidth = 0;
	[widths enumerateObjectsUsingBlock:^(NSNumber * _Nonnull val, NSUInteger idx, BOOL * _Nonnull stop) {
		sumWidth += [val floatValue];
	}];
	
	[keys enumerateObjectsUsingBlock:^(NSString * _Nonnull keyValue, NSUInteger idx, BOOL * _Nonnull stop) {
		//Create button
		GlossyButton *button = [[GlossyButton alloc] initWithFrame:CGRectMake (0, 0, 0, 0)];

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
	} else if ([keyValue hasPrefix:@"Ex"]) { //Extra key
		//TODO: handle extra keys ...
	} else { //Normal value key
		[button addTarget:self action:@selector (keyPressed:) forControlEvents:UIControlEventTouchUpInside];
	}
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

-(void) keyPressed:(id)sender {
	UIButton *button = (UIButton*) sender;
	NSString *key = [[button titleLabel] text];
	[[self textDocumentProxy] insertText:key];
}

#pragma mark - Keyboards

//TODO: code all of supported international keyboards

@end
