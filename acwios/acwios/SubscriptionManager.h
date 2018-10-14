//
//  SubscriptionManager.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#define TEST_PURCHASE
#define TEST_PURCHASE_SUCCEEDED
//#define TEST_PURCHASE_FAILED
//#define TEST_PURCHASE_RESTORE_SUCCEEDED
//#define TEST_PURCHASE_RESTORE_FAILED

@protocol SubscriptionManagerDelegate <NSObject>

@required -(void)presentAlert:(UIAlertController*)alert;
@required -(void)dismissVC;

@end

@protocol SubscriptionManagerAlertSetupCallback <NSObject>

@required -(void)setup;

@end

@interface SubscriptionManager : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (weak) id<SubscriptionManagerDelegate> delegate;
@property (weak) id<SubscriptionManagerAlertSetupCallback> callback;

#ifdef TEST_PURCHASE
- (void)deletePurchase;
#endif //TEST_PURCHASE

+(SubscriptionManager*) sharedInstance;

-(void) showSubscriptionAlert:(UIViewController*)parent msg:(NSString*)msg;

-(BOOL) isSubscribed;
-(SKProduct*) getSubscribeProduct;
-(void) buyProduct:(SKProduct*)product;

@end
