//
//  SubscriptionManager.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "SubscriptionManager.h"

//TODO: implement restore purchase

#ifdef TEST_PURCHASE
@interface TestPaymentTransaction : SKPaymentTransaction
@property(nonatomic, strong) NSDate *transactionDate;
@property(nonatomic, assign) SKPaymentTransactionState transactionState;
@property(nonatomic, strong) NSError *error;
@end

@implementation TestPaymentTransaction
@synthesize transactionDate;
@synthesize transactionState;
@synthesize error;
@end
#endif //TEST_PURCHASE

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

-(void) showOKAlert:(NSString*)msg title:(NSString*)title {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
																   message:msg
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK"
													   style:UIAlertActionStyleCancel
													 handler:^(UIAlertAction * _Nonnull action)
	{
		[[self delegate] dismissVC];
	}];
	
	[alert addAction:actionOK];
	
	[[self delegate] presentAlert:alert];
}

- (BOOL) ensureDirExists:(NSURL*)dir {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	BOOL isDir = NO;
	BOOL exists = [fileManager fileExistsAtPath:[dir path] isDirectory:&isDir] == YES;
	
	BOOL createDir = NO;
	if (!exists) { //We have nothing at destination, so let's create a dir...
		createDir = YES;
	} else if (!isDir) { //We have some file at place, so we have to delete it before creating the dir...
		NSError *err = nil;
		if ([fileManager removeItemAtPath:[dir path] error:&err] != YES) {
			NSLog (@"Cannot remove file at path: %@, err: %@", [dir path], err);
			return NO;
		}
		createDir = YES;
	}
	
	if (createDir) {
		NSError *err = nil;
		if ([fileManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&err] != YES) {
			NSLog (@"Cannot create database at url: %@, err: %@", dir, err);
			return NO;
		}
	}
	
	return YES;
}

- (NSURL*) purchasePath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *appSupportDir = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	if (![self ensureDirExists:appSupportDir]) {
		return nil;
	}
	

	NSURL *purchasePath = [appSupportDir URLByAppendingPathComponent:@"purchase.dat" isDirectory:NO];
	return purchasePath;
}

#ifdef TEST_PURCHASE
- (void)deletePurchase {
	[[NSFileManager defaultManager] removeItemAtURL:[self purchasePath] error:nil];
}
#endif //TEST_PURCHASE

-(BOOL) storePurchaseDate:(NSDate*)purchaseDate {
	NSString *str = [NSString stringWithFormat:@"%lli", (int64_t) [purchaseDate timeIntervalSince1970]];
	
	NSError *err = nil;
	if (![str writeToURL:[self purchasePath] atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
		[self showOKAlert:@"Cannot store Your purchase on local storage!" title:@"Error"];
		return NO;
	}
	
	return YES;
}

-(NSDate*) expirationDate {
	NSError *err = nil;
	NSString *strDate = [NSString stringWithContentsOfURL:[self purchasePath] encoding:NSUTF8StringEncoding error:&err];
	if (strDate == nil) {
		return nil;
	}
	
	int64_t unixValue = [strDate longLongValue];
	NSDate *purchaseDate = [NSDate dateWithTimeIntervalSince1970:unixValue];
	
	NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
	[dateComponents setMonth:1];
	[dateComponents setDay:14]; //+ 2 weeks lease
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDate *expirationDatePlusLease = [calendar dateByAddingComponents:dateComponents toDate:purchaseDate options:0];
	return expirationDatePlusLease;
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
	NSDate *expiration = [self expirationDate];
	if (expiration == nil) {
		return NO;
	}
	
	NSDate *cur = [NSDate new];
	if ([expiration compare:cur] == NSOrderedDescending) {
		return YES;
	}
	
	return NO;
}

-(SKProduct*) getSubscribeProduct {
#ifdef TEST_PURCHASE
	//////////////////////////
	// Test purchases
	//////////////////////////
	
	return [[SKProduct alloc] init];
	
#else //TEST_PURCHASE
	//////////////////////////
	// Production purchase
	//////////////////////////
	
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
	
#endif //TEST_PURCHASE
}

-(void) buyProduct:(SKProduct*)product {
#ifdef TEST_PURCHASE
	//////////////////////////
	// Test purchases
	//////////////////////////
	
	TestPaymentTransaction *testTransaction = [[TestPaymentTransaction alloc] init];
	SKPaymentQueue *queue = nil;
	testTransaction.transactionDate = [NSDate new];
#	ifdef TEST_PURCHASE_SUCCEEDED
	testTransaction.transactionState = SKPaymentTransactionStatePurchased;
#	elif defined(TEST_PURCHASE_FAILED)
	testTransaction.transactionState = SKPaymentTransactionStateFailed;
	testTransaction.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
#	endif //TEST_PURCHASE_SUCCEEDED
	[self paymentQueue:queue updatedTransactions:@[testTransaction]];
	
#else //TEST_PURCHASE
	//////////////////////////
	// Production purchase
	//////////////////////////

	SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
	payment.quantity = 1;
	[[SKPaymentQueue defaultQueue] addPayment:payment];
	
#endif //TEST_PURCHASE
}

//TODO: implement restore of purchases

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
	NSMutableArray<NSError*> *errors = [NSMutableArray<NSError*> new];
	for (SKPaymentTransaction* transaction in transactions) {
		switch ([transaction transactionState]) {
			case SKPaymentTransactionStatePurchasing:
				//... Nothing to do here ...
				break;
			case SKPaymentTransactionStateDeferred:
				//... Nothing to do here ...
				break;
			case SKPaymentTransactionStatePurchased:
				if ([self storePurchaseDate:transaction.transactionDate]) {
					[queue finishTransaction:transaction];
					[self showOKAlert:@"Subscription purchased successfully!" title:@"Success"];
				}
				break;
			case SKPaymentTransactionStateRestored:
				if ([self storePurchaseDate:transaction.transactionDate]) {
					[queue finishTransaction:transaction];
					[self showOKAlert:@"Subscription restored successfully!" title:@"Success"];
				}
				break;
			case SKPaymentTransactionStateFailed:
				[errors addObject:[transaction error]];
				break;
			default:
				// For debugging
				NSLog (@"Unexpected transaction state %@", @(transaction.transactionState));
				break;
		}
	}
	
	if ([errors count] > 0) {
		NSString *msg = [NSString stringWithFormat:@"%lu pcs of payment transaction(s) failed! First errors: %@",
						 [errors count],
						 [[errors objectAtIndex:0] description]];
		[self showOKAlert:msg title:@"Error"];
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	NSString *msg = [NSString stringWithFormat:@"Restoring of subscription failed! Error: %@", [error description]];
	[self showOKAlert:msg title:@"Error"];
}

@end
