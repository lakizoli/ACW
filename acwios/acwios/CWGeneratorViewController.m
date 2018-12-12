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
#import "ProgressView.h"

@interface CWGeneratorViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textCrosswordName;
@property (weak, nonatomic) IBOutlet UITextField *textWidth;
@property (weak, nonatomic) IBOutlet UITextField *textHeight;
@property (weak, nonatomic) IBOutlet UILabel *labelQuestion;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerQuestion;
@property (weak, nonatomic) IBOutlet UILabel *labelSolution;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerSolution;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet ProgressView *progressView;
@property (weak, nonatomic) IBOutlet UISwitch *switchGenerateAllVariations;

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

-(void) showSubscription:(NSInteger)maxSize {
	NSString *msg = [NSString stringWithFormat:@"You have to subscribe to the application to generate crossword with a size more than %li!", maxSize];
	[[SubscriptionManager sharedInstance] showSubscriptionAlert:self msg:msg];
}

-(void) showMaximalSizeAlert:(NSInteger)maxSize {
	NSString *msg = [NSString stringWithFormat:@"You can enter only smaller sizes, than the maximal crossword size of %li!", maxSize];
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Maximal size limit reached!"
																   message:msg
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		//... nothing to do ...
	}];
	[alert addAction: action];
	
	[self presentViewController:alert animated:YES completion:nil];
}

-(void) showMinimalSizeAlert:(NSInteger)minSize {
	NSString *msg = [NSString stringWithFormat:@"You can enter only bigger sizes, than the minimal crossword size of %li!", minSize];
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Minimal size limit reached!"
																   message:msg
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		//... nothing to do ...
	}];
	[alert addAction: action];
	
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

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
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

- (void)viewWillAppear:(BOOL)animated {
	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
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
	//Resign first responders
	if ([_textCrosswordName isFirstResponder]) {
		[_textCrosswordName resignFirstResponder];
	}
	
	if ([_textWidth isFirstResponder]) {
		[_textWidth resignFirstResponder];
	}
	
	if ([_textHeight isFirstResponder]) {
		[_textHeight resignFirstResponder];
	}
	
	//Show progress
	__block volatile BOOL isGenerationCancelled = NO;

	[_doneButton setEnabled:NO];
	[_progressView setHidden:NO];
	
	[_progressView setLabelContent:@"Generating crossword..."];
	[_progressView setButtonLabel:@"Cancel"];
	[_progressView setOnButtonPressed:^{
		isGenerationCancelled = YES;
	}];

	//Fill info with configuration values
	[_generatorInfo setCrosswordName: _crosswordName];
	[_generatorInfo setWidth: _width];
	[_generatorInfo setHeight: _height];
	[_generatorInfo setQuestionFieldIndex: _questionFieldIndex];
	[_generatorInfo setSolutionFieldIndex: _solutionFieldIndex];
	
	//Generate crossword
	__block BOOL generateAllVariations = [_switchGenerateAllVariations isOn];
	dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		__block int32_t lastPercent = -1;

		NSString *baseName;
		if (generateAllVariations) {
			baseName = [self->_generatorInfo crosswordName];
		}

		BOOL genRes = YES;
		int32_t idx = 0;
		while (genRes) {
			if (generateAllVariations) {
				lastPercent = -1;
				
				//Reload used words
				NSURL *packagePath = [[[self->_decks objectAtIndex:0] package] path];
				[[PackageManager sharedInstance] reloadUsedWords:packagePath info:self->_generatorInfo];

				//Add counted name to info
				NSString *countedName = [baseName stringByAppendingString:[NSString stringWithFormat:@" - {%d}", ++idx]];
				[self->_generatorInfo setCrosswordName:countedName];
			}
			
			genRes = [[PackageManager sharedInstance] generateWithInfo:self->_generatorInfo progressCallback:^(float percent, BOOL *stop) {
				int32_t percentVal = (int32_t) (percent * 100.0f + 0.5f);
				if (percentVal != lastPercent) {
					lastPercent = percentVal;
					
					dispatch_async (dispatch_get_main_queue (), ^(void) {
						[self->_progressView setProgressValue:percent];
					});
				}
				
				if (isGenerationCancelled) {
					*stop = YES;
				}
			}];
			
			if (generateAllVariations == NO) {
				break;
			}
		}

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
				[self showMaximalSizeAlert:maxSize];
			} else { //Subscription alert
				[self showSubscription:maxSize];
			}

			[textField setText:[NSString stringWithFormat:@"%li", maxSize]];
			
			if (textField == _textWidth) {
				_width = (NSUInteger) maxSize;
			} else if (textField == _textHeight) {
				_height = (NSUInteger) maxSize;
			}
		} else if (givenSize < 5) { //Minimal size is 5
			[self showMinimalSizeAlert:5];
			
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
