//
//  SubscriptionManager.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SubscriptionManager : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>

+(SubscriptionManager*) sharedInstance;

-(void) showSubscriptionAlert:(UIViewController*)parent msg:(NSString*)msg;

-(BOOL) isSubscribed;
-(SKProduct*) getSubscribeProduct;

@end
