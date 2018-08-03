//
//  PackageManager.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Package.h"

@interface PackageManager : NSObject

+(PackageManager*) sharedInstance;

-(NSArray<Package*>*)collectPackages;
-(NSArray<Card*>*)collectCardsOfDeck:(Deck*)deck;

@end
