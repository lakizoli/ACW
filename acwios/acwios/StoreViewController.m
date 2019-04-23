//
//  StoreViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 10. 05..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "StoreViewController.h"
#import "SubscriptionManager.h"
#import "GlossyButton.h"

@interface StoreViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet GlossyButton *buyMonthButton;
@property (weak, nonatomic) IBOutlet GlossyButton *buyYearButton;
@property (weak, nonatomic) IBOutlet GlossyButton *restoreButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;

@end

@implementation StoreViewController {
	SKProduct *_productMonth;
	SKProduct *_productYear;
}

#pragma mark - Implementation

- (NSString*)priceForProduct:(SKProduct*)product postFix:(NSString*)postFix {
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:product.priceLocale];
	NSString *formattedPriceString = [numberFormatter stringFromNumber:product.price];
	return [formattedPriceString stringByAppendingString:postFix];
}

- (void)enableStore:(BOOL)enable {
	[_backButton setEnabled:enable];
	[_restoreButton setEnabled:enable];
	[_buyMonthButton setEnabled:enable];
	[_buyYearButton setEnabled:enable];
	if (enable) {
		NSString *priceMonth = [self priceForProduct:_productMonth postFix:@" / Month"];
		[_buyMonthButton setTitle:priceMonth forState:UIControlStateNormal];
		
		NSString *priceYear = [self priceForProduct:_productYear postFix:@" / Year (Save 20%)"];
		[_buyYearButton setTitle:priceYear forState:UIControlStateNormal];
		
		[_progressIndicator stopAnimating];
	} else {
		[_progressIndicator startAnimating];
	}
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
	[[SubscriptionManager sharedInstance] setDelegate:self];
	[self enableStore:NO];
	
#ifdef TEST_PURCHASE
	if (1) {
#else //TEST_PURCHASE
	if ([SKPaymentQueue canMakePayments] == YES) {
#endif //TEST_PURCHASE
		dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
			SubscriptionManager *man = [SubscriptionManager sharedInstance];
			NSDate *start = [NSDate new];
			while (self->_productMonth == nil || self->_productYear == nil) {
				if (self->_productMonth == nil) {
					self->_productMonth = [man getSubscribedProductForMonth];
				}
				
				if (self->_productYear == nil) {
					self->_productYear = [man getSubscribedProductForYear];
				}
				
				NSDate *cur = [NSDate new];
				NSTimeInterval duration = [cur timeIntervalSinceDate:start];
				if (duration > 30) { //Timeout is 30 seconds
					UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
																				   message:@"Product to subscribe not found!"
																			preferredStyle:UIAlertControllerStyleAlert];
					
					UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK"
																	   style:UIAlertActionStyleCancel
																	 handler:^(UIAlertAction * _Nonnull action)
					{
						[self dismissViewControllerAnimated:YES completion:nil];
					}];
					
					[alert addAction:actionOK];
					
					[self presentViewController:alert animated:YES completion:nil];
					return;
				}
			}

			if (self->_productMonth && self->_productYear) {
				dispatch_async (dispatch_get_main_queue (), ^{
					[self enableStore:YES];
				});
			}
		});
	}
}

- (void)viewDidAppear:(BOOL)animated {
#ifdef TEST_PURCHASE
	if (0) {
#else //TEST_PURCHASE
	if ([SKPaymentQueue canMakePayments] == NO) {
#endif //TEST_PURCHASE
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
																	   message:@"In app purchase is disabled, so you cannot subscribe to this application!"
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK"
														   style:UIAlertActionStyleCancel
														 handler:^(UIAlertAction * _Nonnull action)
		{
			[self dismissViewControllerAnimated:YES completion:nil];
		}];
		
		[alert addAction:actionOK];
		
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (IBAction)buyMonthPressed:(id)sender {
	[self enableStore:NO];
	[[SubscriptionManager sharedInstance] buyProduct:_productMonth];
}

- (IBAction)buyYearPressed:(id)sender {
	[self enableStore:NO];
	[[SubscriptionManager sharedInstance] buyProduct:_productYear];
}

- (IBAction)restoreButtonPressed:(id)sender {
	[self enableStore:NO];
	[[SubscriptionManager sharedInstance] restoreProducts];
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
		return [super supportedInterfaceOrientations];
	}
	
	[super supportedInterfaceOrientations];
	return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
		return [super shouldAutorotate];
	}
	
	[super shouldAutorotate];
	return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
		return [super preferredInterfaceOrientationForPresentation];
	}
	
	[super preferredInterfaceOrientationForPresentation];
	return UIInterfaceOrientationPortrait;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
	
#pragma mark - SubscriptionManagerDelegate
	
- (void)presentAlert:(UIAlertController *)alert {
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)dismissVC {
	[self dismissViewControllerAnimated:YES completion:nil];
}
	
@end
