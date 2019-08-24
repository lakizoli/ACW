//
//  NetLogger.h
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 24..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetLogger : NSObject

+(void)logEvent:(NSString *)eventName;
+(void)logEvent:(NSString *)eventName withParameters:(NSDictionary<NSString *,NSObject *> *)params;

@end

NS_ASSUME_NONNULL_END
