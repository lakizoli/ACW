//
//  NetLogger.h
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 24..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetLogger : NSObject

+(void)startSession;
+(void)logEvent:(NSString *)eventName;
+(void)logEvent:(NSString *)eventName withParameters:(NSDictionary<NSString *,NSObject *> *)params;
+(void)logPaymentTransaction:(SKPaymentTransaction*)transaction;

@end

NS_ASSUME_NONNULL_END
