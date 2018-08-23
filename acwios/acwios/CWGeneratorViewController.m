//
//  CWGeneratorViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 08. 03..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "CWGeneratorViewController.h"
#import "SubscriptionManager.h"
#import "PackageManager.h"

@interface CWGeneratorViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textCrosswordName;
@property (weak, nonatomic) IBOutlet UITextField *textWidth;
@property (weak, nonatomic) IBOutlet UITextField *textHeight;
@property (weak, nonatomic) IBOutlet UILabel *labelQuestion;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerQuestion;
@property (weak, nonatomic) IBOutlet UILabel *labelSolution;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerSolution;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation CWGeneratorViewController {
	BOOL _isSubscribed;
	GeneratorInfo *_generatorInfo;
	
	NSString *_crosswordName;
	NSUInteger _width;
	NSUInteger _height;
	NSUInteger _questionFieldIndex;
	NSUInteger _solutionFieldIndex;
}

#pragma mark - Implementation

-(void) showSubscription {
	//TODO: implement subscribtion process in SubScriptionManager...
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subscribe" message:@"Let's take some subscription..." preferredStyle:UIAlertControllerStyleAlert];
	
	[self presentViewController:alert animated:YES completion:nil];
}

-(void) showNameAlert {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Name error" message:@"You have to give a name for the generated crossword!" preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * action) {}];
	
	[alert addAction:defaultAction];
	[self presentViewController:alert animated:YES completion:nil];
}

-(NSString*) getFieldValue:(NSUInteger)row {
	NSString *fieldValue = nil;
	
	NSArray<Field*> *fields = [_generatorInfo fields];
	if (row < [fields count]) {
		Field *field = [fields objectAtIndex:row];
		NSArray<Card*> *cards = [_generatorInfo cards];
		
		if ([cards count] > 0) {
			Card *card = [cards objectAtIndex:0];
			if ([field idx] < [[card fieldValues] count]) {
				fieldValue = [[card fieldValues] objectAtIndex:[field idx]];
			}
		}
	}
	
	return fieldValue;
}

-(void) updatePickerLabel:(UILabel*)label withText:(NSString*)text andExample:(NSString*)exampleContent {
	if (exampleContent == nil) {
		[label setText:text];
		return;
	}
	
	NSString *example = [NSString stringWithFormat:@"(e.g.: \"%@\")", exampleContent];
	NSString *content = [NSString stringWithFormat:@"%@ %@", text, example];
	NSDictionary *attribs = @{ NSForegroundColorAttributeName: label.textColor,
							   NSFontAttributeName: label.font };
	NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:content attributes:attribs];
	
	UIColor *grayColor = [UIColor grayColor];
	NSRange grayTextRange = [content rangeOfString:example];
	UIFont *italicFont = [UIFont italicSystemFontOfSize: label.font.pointSize];
	[attributedText setAttributes:@{ NSForegroundColorAttributeName:grayColor,
									 NSFontAttributeName: italicFont }
							range:grayTextRange];
	
	[label setAttributedText:attributedText];
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	_generatorInfo = [[PackageManager sharedInstance] collectGeneratorInfo:_decks];
	
	if ([[_generatorInfo decks] count] > 0) {
		Deck* firstDeck = [[_generatorInfo decks] objectAtIndex:0];
		_crosswordName = [firstDeck name];
	}
	
	_width = 5;
	_height = 5;
	
	_questionFieldIndex = 0;
	_solutionFieldIndex = 0;
}

- (void)viewDidAppear:(BOOL)animated {
	[_textCrosswordName setText:_crosswordName];
	[_textWidth setText:[NSString stringWithFormat:@"%lu", _width]];
	[_textHeight setText:[NSString stringWithFormat:@"%lu", _height]];
	
	PackageManager* pacMan = [PackageManager sharedInstance];
	
	NSString *fieldValue = [self getFieldValue:_questionFieldIndex];
	[self updatePickerLabel:_labelQuestion withText:@"Question field:" andExample:[pacMan trimQuestionField: fieldValue]];
	
	fieldValue = [self getFieldValue:_solutionFieldIndex];
	[self updatePickerLabel:_labelSolution withText:@"Solution field:" andExample:[pacMan trimSolutionField: fieldValue]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtorPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneButtonPressed:(id)sender {
	//Fill info with configuration values
	[_generatorInfo setCrosswordName: _crosswordName];
	[_generatorInfo setWidth: _width];
	[_generatorInfo setHeight: _height];
	[_generatorInfo setQuestionFieldIndex: _questionFieldIndex];
	[_generatorInfo setSolutionFieldIndex: _solutionFieldIndex];
	
	//Generate crossword
	[_doneButton setEnabled:NO];
	dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		[[PackageManager sharedInstance] generateWithInfo:self->_generatorInfo];

		dispatch_async (dispatch_get_main_queue (), ^(void) {
			__block UIViewController *parent = [self presentingViewController];
			[self dismissViewControllerAnimated:YES completion: ^(void) {
				[parent dismissViewControllerAnimated:YES completion:nil];
			}];
		});
	});
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (textField == _textWidth || textField == _textHeight) {
		NSInteger maxSize = _isSubscribed ? 99 : 10;
		NSInteger givenSize = [[textField text] integerValue];

		if (givenSize > maxSize) { //Show alert for user
			if (_isSubscribed) { //Size alert
				//TODO: show size alert...
			} else { //Subscription alert
				[self showSubscription];
			}

			[textField setText:[NSString stringWithFormat:@"%li", maxSize]];
			
			if (textField == _textWidth) {
				_width = (NSUInteger) maxSize;
			} else if (textField == _textHeight) {
				_height = (NSUInteger) maxSize;
			}
		} else if (givenSize < 5) { //Minimal size is 5
			//TODO: show size alert...
			
			[textField setText:@"5"];
			
			if (textField == _textWidth) {
				_width = 5;
			} else if (textField == _textHeight) {
				_height = 5;
			}
		} else { //Allowed size given
			if (textField == _textWidth) {
				_width = (NSUInteger) givenSize;
			} else if (textField == _textHeight) {
				_height = (NSUInteger) givenSize;
			}
		}
	} else if (textField == _textCrosswordName) {
		if ([[textField text] length] <= 0) {
			[self showNameAlert];
		}
		
		_crosswordName = [textField text];
	}

	return YES;
}

#pragma mark - Picker view datasource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	if (pickerView == _pickerQuestion || pickerView == _pickerSolution) {
		return 1;
	}
	
	return 0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	if (pickerView == _pickerQuestion) {
		return [[_generatorInfo fields] count];
	} else if (pickerView == _pickerSolution) {
		return [[_generatorInfo fields] count];
	}

	return 0;
}

#pragma mark - Picker view delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	if (pickerView == _pickerQuestion) {
		return [[[_generatorInfo fields] objectAtIndex:row] name];
	} else if (pickerView == _pickerSolution) {
		return [[[_generatorInfo fields] objectAtIndex:row] name];
	}

	return nil;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	if (pickerView == _pickerQuestion) {
		NSString *fieldValue = [self getFieldValue:row];
		[self updatePickerLabel:_labelQuestion withText:@"Question field:" andExample:[[PackageManager sharedInstance] trimQuestionField:fieldValue]];
		_questionFieldIndex = row;
	} else if (pickerView == _pickerSolution) {
		NSString *fieldValue = [self getFieldValue:row];
		[self updatePickerLabel:_labelSolution withText:@"Solution field:" andExample:[[PackageManager sharedInstance] trimSolutionField:fieldValue]];
		_solutionFieldIndex = row;
	}
}

@end
