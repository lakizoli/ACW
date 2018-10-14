//
//  StoreViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 10. 05..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "StoreViewController.h"
#import "SubscriptionManager.h"

@interface StoreViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;

@end

@implementation StoreViewController

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
	if ([SKPaymentQueue canMakePayments] == YES) {
		dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
			SubscriptionManager *man = [SubscriptionManager sharedInstance];
			SKProduct *product = nil;
			while ( (product = [man getSubscribeProduct]) == nil ) {
				//TODO: handle timeout
			}

			dispatch_async (dispatch_get_main_queue (), ^{
				[self->_progressIndicator stopAnimating];
			});
		});
	}
}

- (void)viewDidAppear:(BOOL)animated {
	if ([SKPaymentQueue canMakePayments] == NO) {
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
	NSLog (@"buy");
	//TODO: buy the subscription product
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

@end
