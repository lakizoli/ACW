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
@property (weak, nonatomic) IBOutlet GlossyButton *buyButton;
@property (weak, nonatomic) IBOutlet GlossyButton *restoreButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;

@end

@implementation StoreViewController {
	SKProduct *_product;
}

#pragma mark - Implementation

- (void)enableStore:(BOOL)enable {
	[_backButton setEnabled:enable];
	[_restoreButton setEnabled:enable];
	[_buyButton setEnabled:enable];
	if (enable) {
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
			while ( (self->_product = [man getSubscribeProduct]) == nil ) {
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

			if (self->_product) {
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
																	   message:@"In app purchase is disabled, so You cannot subscribe to this application!"
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

- (IBAction)buyButtonPressed:(id)sender {
	[self enableStore:NO];
	[[SubscriptionManager sharedInstance] buyProduct:_product];
}

- (IBAction)restoreButtonPressed:(id)sender {
	NSLog (@"restore");
	//TODO: restore the subscription product
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
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
