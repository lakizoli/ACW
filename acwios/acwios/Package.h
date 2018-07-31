//
//  Package.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Package : NSObject

@property (assign) NSUInteger deckID;
@property (strong) NSString *name;
@property (strong) NSURL *path;

@end
