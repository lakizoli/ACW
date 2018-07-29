//
//  SubscriptionManager.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SubscriptionManager : NSObject

+(SubscriptionManager*) sharedInstance;

-(BOOL) isSubscribed;

@end
