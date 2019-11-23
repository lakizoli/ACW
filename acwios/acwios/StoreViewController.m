//
//  StoreViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 10. 05..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "StoreViewController.h"
#import "SubscriptionManager.h"
#import "NetLogger.h"

@interface StoreViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;
@property (weak, nonatomic) IBOutlet WKWebView *contentWebView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;

@end

@implementation StoreViewController {
	BOOL _isInInnerDocument; //Terms of use, or privacy policy
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
	if (enable) {
		[_navBar.topItem setTitle:@"Store"];
		_isInInnerDocument = NO;
		
		NSString *priceMonth = [self priceForProduct:_productMonth postFix:@" / Month"];
		NSString *priceYear = [self priceForProduct:_productYear postFix:@" / Year"];

		NSURL *url = [[NSBundle mainBundle] URLForResource:@"considerations" withExtension:@"html"];
		NSString *html = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
		html = [html stringByReplacingOccurrencesOfString:@"##MonthlyPrice##" withString:priceMonth];
		html = [html stringByReplacingOccurrencesOfString:@"##YearlyPrice##" withString:priceYear];
		[_contentWebView loadHTMLString:html baseURL:nil];
		[_contentWebView.scrollView setScrollEnabled:NO];
		[_contentWebView setNavigationDelegate:self];

		[_progressIndicator stopAnimating];
	} else {
		[_progressIndicator startAnimating];
	}
}

#pragma mark - Appereance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[NetLogger logEvent:@"Store_ShowView"];
	
    // Do any additional setup after loading the view.
	_isInInnerDocument = NO;
	
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
	[super viewDidAppear:animated];
	
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

- (IBAction)backButtonPressed:(id)sender {
	if (_isInInnerDocument) {
		[self enableStore:YES];
		return;
	}
	
	[self dismissViewControllerAnimated:YES completion:nil];
}
	
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
//		return [super supportedInterfaceOrientations];
//	}
	
	[super supportedInterfaceOrientations];
	return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
//	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
//		return [super shouldAutorotate];
//	}
	
	[super shouldAutorotate];
	return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
//		return [super preferredInterfaceOrientationForPresentation];
//	}
	
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
	
#pragma mark - WKNavigationDelegate
	
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	NSURL *url = navigationAction.request.URL;
	if ([[url host] hasPrefix:@"ankidoc.com"]) {
		__block NSURL *doc = nil;
		if ([[url path] hasSuffix:@"privacy_policy"]) {
			[_navBar.topItem setTitle:@"Privacy Policy"];
			doc = [[NSBundle mainBundle] URLForResource:@"privacy_policy" withExtension:@"html"];
		} else if ([[url path] hasSuffix:@"terms_of_use"]) {
			[_navBar.topItem setTitle:@"Terms Of Use"];
			doc = [[NSBundle mainBundle] URLForResource:@"terms_of_use" withExtension:@"html"];
		}
		
		if (doc) {
			_isInInnerDocument = YES;
			
			NSString *html = [NSString stringWithContentsOfURL:doc encoding:NSUTF8StringEncoding error:nil];
			[_contentWebView loadHTMLString:html baseURL:nil];
			[_contentWebView.scrollView setScrollEnabled:YES];
		}

		decisionHandler (WKNavigationActionPolicyCancel);
		return;
	} else if ([[url host] hasPrefix:@"ankibuy.com"]) {
		if ([[url path] hasSuffix:@"monthly"]) {
			[self enableStore:NO];
			[[SubscriptionManager sharedInstance] buyProduct:_productMonth];
		} else if ([[url path] hasSuffix:@"yearly"]) {
			[self enableStore:NO];
			[[SubscriptionManager sharedInstance] buyProduct:_productYear];
		} else if ([[url path] hasSuffix:@"restore"]) {
			[self enableStore:NO];
			[[SubscriptionManager sharedInstance] restoreProducts];
		}
					
		decisionHandler (WKNavigationActionPolicyCancel);
		return;
	}
	
	decisionHandler (WKNavigationActionPolicyAllow);
}
	
@end
