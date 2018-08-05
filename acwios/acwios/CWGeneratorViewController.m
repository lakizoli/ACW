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

@property (weak, nonatomic) IBOutlet UITextField *textWidth;
@property (weak, nonatomic) IBOutlet UITextField *textHeight;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerQuestion;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerSolution;

@end

@implementation CWGeneratorViewController {
	BOOL _isSubscribed;
	GeneratorInfo *_generatorInfo;
}

#pragma mark - Implementation

-(void) showSubscription {
	//TODO: implement subscribtion process in SubScriptionManager...
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subscribe" message:@"Let's take some subscription..." preferredStyle:UIAlertControllerStyleAlert];
	
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
//	[_textWidth setText:@"5"];
//	[_textHeight setText:@"5"];

	_isSubscribed = [[SubscriptionManager sharedInstance] isSubscribed];
	//TODO: ... handle subscribe check for generation ...
	
	_generatorInfo = [[PackageManager sharedInstance] collectGeneratorInfo:_deck];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtorPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)doneButtonPressed:(id)sender {
	//TODO: generate crossword with given settings (have to consider subscribe also!)...
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (textField == _textWidth || textField == _textHeight) {
		NSCharacterSet *numbersOnly = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
		NSCharacterSet *characterSetFromTextField = [NSCharacterSet characterSetWithCharactersInString:string];
		if ([numbersOnly isSupersetOfSet:characterSetFromTextField] && textField.text.length < 2) { //Allow max: 99 in size fields
			return YES;
		}
		
		return NO;
	}
	
	//Other text fields
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (textField == _textWidth || textField == _textHeight) {
		NSInteger maxSize = _isSubscribed ? 99 : 10;
		NSInteger givenSize = [[textField text] integerValue];
		
		if (givenSize > maxSize) { //Show alert for user
			if (!_isSubscribed) {
				[self showSubscription];
			}
			
			[textField setText:[NSString stringWithFormat:@"%li", maxSize]];
		} else if (givenSize < 5) {
			[textField setText:@"5"];
		}
	}
	
	//Other text fields
	return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
		//TODO: ... show example in header upon select ...
		//TODO: ... handle select of picker view ...
	} else if (pickerView == _pickerSolution) {
		//TODO: ... show example in header upon select ...
		//TODO: ... handle select of picker view ...
	}
}

@end
