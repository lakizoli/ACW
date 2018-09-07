//
//  KeyboardViewController.h
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 06..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeyboardViewController : UIInputViewController

@property (strong) NSSet<NSString*> *usedKeys;

-(void) setup;

@end
