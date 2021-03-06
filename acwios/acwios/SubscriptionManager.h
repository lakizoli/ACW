//
//  SubscriptionManager.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

// Testing in app purchase
//#define TEST_PURCHASE
//#define TEST_SANDBOX_PURCHASE //5, 30, 60 minute purchase limit

// Answer types of in app purchase test
//#define TEST_PURCHASE_SUCCEEDED
//#define TEST_PURCHASE_FAILED
//#define TEST_PURCHASE_RESTORE_SUCCEEDED
//#define TEST_PURCHASE_RESTORE_FAILED

@protocol SubscriptionManagerDelegate <NSObject>

@required -(void)presentAlert:(UIAlertController*)alert;
@required -(void)dismissVC;

@end

@interface SubscriptionManager : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (weak) id<SubscriptionManagerDelegate> delegate;

#ifdef TEST_PURCHASE
- (void)deletePurchase;
#endif //TEST_PURCHASE

+(SubscriptionManager*) sharedInstance;

-(void) showStore:(UIViewController *)parent;
-(void) showSubscriptionAlert:(UIViewController*)parent msg:(NSString*)msg;

-(BOOL) isSubscribed;
-(SKProduct*) getSubscribedProductForMonth;
-(SKProduct*) getSubscribedProductForYear;
-(void) buyProduct:(SKProduct*)product;
-(void) restoreProducts;

@end
