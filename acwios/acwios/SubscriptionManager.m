//
//  SubscriptionManager.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "SubscriptionManager.h"

@implementation SubscriptionManager

-(id)init {
	self = [super init];
	if (self) {
		//...
	}
	return self;
}

+(SubscriptionManager*) sharedInstance {
	static SubscriptionManager *instance = nil;
	if (instance == nil) {
		instance = [[SubscriptionManager alloc] init];
	}
	return instance;
}

-(BOOL) isSubscribed {
	//TODO: do the subscription check...
	//return NO;
	return YES;
}

@end
