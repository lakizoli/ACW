//
//  SubscriptionManager.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "SubscriptionManager.h"
#import "NetLogger.h"

#ifdef TEST_PURCHASE
@interface TestPaymentTransaction : SKPaymentTransaction
@property(nonatomic, strong) NSDate *transactionDate;
@property(nonatomic, assign) SKPaymentTransactionState transactionState;
@property(nonatomic, assign) SKPayment *payment;
@property(nonatomic, strong) NSError *error;
@end

@implementation TestPaymentTransaction
@synthesize transactionDate;
@synthesize transactionState;
@synthesize payment;
@synthesize error;
@end

@interface TestPayment : SKMutablePayment
@property(nonatomic, copy) NSString *productIdentifier;
@end

@implementation TestPayment
@synthesize productIdentifier;
@end

@interface TestProduct : SKProduct
@property(nonatomic, strong) NSDecimalNumber *price;
@property(nonatomic, strong) NSLocale *priceLocale;
@property(nonatomic, strong) NSString *productIdentifier;
@end

@implementation TestProduct
@synthesize price;
@synthesize priceLocale;
@synthesize productIdentifier;
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

#define MONTH_INDEX 0
#define YEAR_INDEX 1

-(NSArray<NSString*>*) productIDs {
	//NOTE: keep in order or change expirationDate() and getSubscribedProduct...() calls!
	return @[ @"com.zapp.acw.monthlysubscription",
			  @"com.zapp.acw.yearlysubscription" ];
}

-(SKProduct*) getSubscribedProductWithID:(NSString*)productID {
#ifdef TEST_PURCHASE
	//////////////////////////
	// Test purchases
	//////////////////////////
	
	TestProduct *prod = [[TestProduct alloc] init];
	prod.productIdentifier = productID;
	prod.priceLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	if ([productID isEqualToString:@"com.zapp.acw.monthlysubscription"]) {
		prod.price = [NSDecimalNumber decimalNumberWithString:@"0.99"];
	} else {
		prod.price = [NSDecimalNumber decimalNumberWithString:@"9.99"];
	}
	return prod;
	
#else //TEST_PURCHASE
	//////////////////////////
	// Production purchase
	//////////////////////////
	
	for (SKProduct *prod in _products) {
		if ([productID compare:prod.productIdentifier] == NSOrderedSame) {
			return prod;
		}
	}
	
	return nil;
	
#endif //TEST_PURCHASE
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

-(BOOL) storePurchaseDate:(NSDate*)purchaseDate productID:(NSString*)productID {
	NSString *str = [NSString stringWithFormat:@"%lli:%@", (int64_t) [purchaseDate timeIntervalSince1970], productID];
	
	NSError *err = nil;
	if (![str writeToURL:[self purchasePath] atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
		[self showOKAlert:@"Cannot store your purchase on local storage!" title:@"Error"];
		return NO;
	}
	
	return YES;
}

-(NSDate*) expirationDate {
	NSError *err = nil;
	NSString *strDateAndProductID = [NSString stringWithContentsOfURL:[self purchasePath] encoding:NSUTF8StringEncoding error:&err];
	if (strDateAndProductID == nil) {
		return nil;
	}
	
	NSArray *values = [strDateAndProductID componentsSeparatedByString:@":"];
	if ([values count] < 2) {
		return nil;
	}
	
	int64_t unixValue = [[values objectAtIndex:0] longLongValue];
	NSDate *purchaseDate = [NSDate dateWithTimeIntervalSince1970:unixValue];
	
	NSString *productID = [values objectAtIndex:1];
	NSArray<NSString*> *usedProductIDs = [self productIDs];

	NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
#ifdef TEST_SANDBOX_PURCHASE
	if ([productID compare:[usedProductIDs objectAtIndex:MONTH_INDEX]] == NSOrderedSame) { //Monthly subscription
		[dateComponents setMinute:5];
	} else if ([productID compare:[usedProductIDs objectAtIndex:YEAR_INDEX]] == NSOrderedSame) { //Yearly subscription
		[dateComponents setMinute:60];
	} else {
		return nil;
	}
#else //TEST_SANDBOX_PURCHASE
	//////////////////////////////
	// Real purchase expiration date (1 month + 3 day lease time)
	//////////////////////////////
	
	if ([productID compare:[usedProductIDs objectAtIndex:MONTH_INDEX]] == NSOrderedSame) { //Monthly subscription
		[dateComponents setMonth:1];
	} else if ([productID compare:[usedProductIDs objectAtIndex:YEAR_INDEX]] == NSOrderedSame) { //Yearly subscription
		[dateComponents setYear:1];
	} else {
		return nil;
	}
	[dateComponents setDay:3]; //+ 3 days lease
#endif //TEST_SANDBOX_PURCHASE
	
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

- (void)showStore:(UIViewController *)parent {
	UIViewController *storeVC = [parent.storyboard instantiateViewControllerWithIdentifier:@"StoreVC"];
	
	dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		[self validateProductIDs:[self productIDs]];
	});
	
	[parent presentViewController:storeVC animated:YES completion:nil];
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
		[self showStore:parent];
//		UIViewController *storeVC = [parent.storyboard instantiateViewControllerWithIdentifier:@"StoreVC"];
//
//		dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
//			[self validateProductIDs:[self productIDs]];
//		});
//
//		[parent presentViewController:storeVC animated:YES completion:nil];
	}];

	[alert addAction:actionYes];
	
	[parent presentViewController:alert animated:YES completion:nil];
}

-(BOOL) isSubscribed {
	NSDate *expiration = [self expirationDate];
	if (expiration == nil) {
		static BOOL isSended1 = NO;
		if (!isSended1) {
			[NetLogger logEvent:@"Subscription_NotSubscribed" withParameters:@{ @"expirationDate" : @"nil"  }];
			isSended1 = YES;
		}
		
		return NO;
	}
	
	NSDate *cur = [NSDate new];
	if ([expiration compare:cur] == NSOrderedDescending) {
		static BOOL isSended2 = NO;
		if (!isSended2) {
			[NetLogger logEvent:@"Subscription_Subscribed" withParameters:@{ @"expirationDate" : [expiration description], @"currentDate" : [cur description] }];
			isSended2 = YES;
		}
		
		return YES;
	}
	
	static BOOL isSended3 = NO;
	if (!isSended3) {
		[NetLogger logEvent:@"Subscription_NotSubscribed" withParameters:@{ @"expirationDate" : [expiration description] }];
		isSended3 = YES;
	}
	
	return NO;
}

-(SKProduct*) getSubscribedProductForMonth {
	NSArray<NSString*> *ids = [self productIDs];
	NSString *productID = [ids count] > 1 ? [ids objectAtIndex:MONTH_INDEX] : nil;
	return [self getSubscribedProductWithID:productID];
}

-(SKProduct*) getSubscribedProductForYear {
	NSArray<NSString*> *ids = [self productIDs];
	NSString *productID = [ids count] > 1 ? [ids objectAtIndex:YEAR_INDEX] : nil;
	return [self getSubscribedProductWithID:productID];
}

-(void) buyProduct:(SKProduct*)product {
	[NetLogger logEvent:@"Subscription_Buy" withParameters:@{ @"productIdentifier" : product.productIdentifier }];

#ifdef TEST_PURCHASE
	//////////////////////////
	// Test purchases
	//////////////////////////
	
	TestPaymentTransaction *testTransaction = [[TestPaymentTransaction alloc] init];
	SKPaymentQueue *queue = nil;
	testTransaction.transactionDate = [NSDate new];
	
	TestPayment *payment = [[TestPayment alloc] init];
	payment.productIdentifier = product.productIdentifier;
	testTransaction.payment = payment;
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

-(void) restoreProducts {
	[NetLogger logEvent:@"Subscription_Restore"];

#ifdef TEST_PURCHASE
	//////////////////////////
	// Test restore
	//////////////////////////
	
	SKPaymentQueue *queue = nil;
#	ifdef TEST_PURCHASE_RESTORE_SUCCEEDED
	TestPaymentTransaction *testTransaction = [[TestPaymentTransaction alloc] init];
	testTransaction.transactionDate = [NSDate new];
	testTransaction.transactionState = SKPaymentTransactionStateRestored;
	[self paymentQueue:queue updatedTransactions:@[testTransaction]];
#	elif defined(TEST_PURCHASE_RESTORE_FAILED)
	NSError* error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
	[self paymentQueue:queue restoreCompletedTransactionsFailedWithError:error];
#	endif //TEST_PURCHASE_RESTORE_SUCCEEDED
	
#else //TEST_PURCHASE
	//////////////////////////
	// Production restore
	//////////////////////////
	
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	
#endif //TEST_PURCHASE
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
				if ([self storePurchaseDate:transaction.transactionDate productID:transaction.payment.productIdentifier]) {
					[queue finishTransaction:transaction];
					[NetLogger logEvent:@"Subscription_End_Purchased" withParameters:@{ @"productIdentifier" : transaction.payment.productIdentifier }];
					[self showOKAlert:@"Subscription purchased successfully!" title:@"Success"];
				}
				break;
			case SKPaymentTransactionStateRestored:
				if ([self storePurchaseDate:transaction.transactionDate productID:transaction.payment.productIdentifier]) {
					[queue finishTransaction:transaction];
					[NetLogger logEvent:@"Subscription_End_Restored" withParameters:@{ @"productIdentifier" : transaction.payment.productIdentifier }];
					[self showOKAlert:@"Subscription restored successfully!" title:@"Success"];
				}
				break;
			case SKPaymentTransactionStateFailed:
				[errors addObject:[transaction error]];
				[queue finishTransaction:transaction]; //Consume transactions with error!
				[NetLogger logEvent:@"Subscription_End_Failed" withParameters:@{ @"error" : [transaction error] }];
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
