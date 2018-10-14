//
//  SubscriptionManager.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "SubscriptionManager.h"

@implementation SubscriptionManager {
	SKProductsRequest* _productsRequest;
	NSMutableArray<SKProduct*> *_products;
}

-(id)init {
	self = [super init];
	if (self) {
		_productsRequest = nil;
	}
	return self;
}

#pragma mark - Implementation

-(NSArray<NSString*>*) productIDs {
	return @[ @"com.zapp.acwios.subscription" ];
}

-(void) validateProductIDs:(NSArray<NSString*>*)productIDs {
	if (_productsRequest) {
		return;
	}
	
	// Keep a strong reference to the request.
	_productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIDs]];
	_productsRequest.delegate = self;
	[_productsRequest start];
}

#pragma mark - Interface

+(SubscriptionManager*) sharedInstance {
	static SubscriptionManager *instance = nil;
	if (instance == nil) {
		instance = [[SubscriptionManager alloc] init];
	}
	return instance;
}

- (void)showSubscriptionAlert:(UIViewController *)parent msg:(NSString*)msg {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subscribe Alert!" message:msg preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"No"
													   style:UIAlertActionStyleCancel
													 handler:^(UIAlertAction * _Nonnull action)
	{
		//Nothing to do here...
	}];
	
	[alert addAction:actionNo];
	
	UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"Yes"
														style:UIAlertActionStyleDestructive
													  handler:^(UIAlertAction * _Nonnull action)
	{
		UIViewController *storeVC = [parent.storyboard instantiateViewControllerWithIdentifier:@"StoreVC"];
		
		dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
			[self validateProductIDs:[self productIDs]];
		});
		
		[parent presentViewController:storeVC animated:YES completion:nil];
	}];

	[alert addAction:actionYes];
	
	[parent presentViewController:alert animated:YES completion:nil];
}

-(BOOL) isSubscribed {
	//TODO: do the subscription check...
	return NO;
	//return YES;
}

-(SKProduct*) getSubscribeProduct {
	NSArray<NSString*> *ids = [self productIDs];
	
	for (NSString *prodID in ids) {
		for (SKProduct *prod in _products) {
			if ([prodID compare:prod.productIdentifier] == NSOrderedSame) {
				return prod;
			}
		}
		
		break; //We have only one product!
	}
	
	return nil;
}

#pragma mark - SKProductsRequestDelegate

-(void) productsRequest:(nonnull SKProductsRequest *)request didReceiveResponse:(nonnull SKProductsResponse *)response {
	_products = [NSMutableArray<SKProduct*> new];
	
	for (SKProduct* prod in response.products) {
		BOOL isInvalid = NO;
		for (NSString *prodID in response.invalidProductIdentifiers) {
			if ([prodID compare:prod.productIdentifier] == NSOrderedSame) {
				isInvalid = YES;
				break;
			}
		}
		
		if (!isInvalid) {
			[_products addObject:prod];
		}
	}

	_productsRequest = nil;
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(nonnull SKPaymentQueue *)queue updatedTransactions:(nonnull NSArray<SKPaymentTransaction *> *)transactions {
	for (SKPaymentTransaction* transaction in transactions) {
		switch ([transaction transactionState]) {
			case SKPaymentTransactionStatePurchasing:
				//... Nothing to do here ...
				break;
			case SKPaymentTransactionStatePurchased:
				//TODO: Register purchase
				break;
			case SKPaymentTransactionStateFailed:
				//TODO: show error for user
				break;
			case SKPaymentTransactionStateRestored:
				//TODO: Restore purchase
				break;
			case SKPaymentTransactionStateDeferred:
				//... Nothing to do here ...
				break;
			default:
				// For debugging
				NSLog (@"Unexpected transaction state %@", @(transaction.transactionState));
				break;
		}
	}
}

@end
