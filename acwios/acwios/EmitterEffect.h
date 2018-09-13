//
//  EmitterEffect.h
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 13..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface EmitterEffect : NSObject

-(void) startSparkler:(UIView*)view pt:(CGPoint)pt;
-(void) startFireWorks:(UIView*)view pt:(CGPoint)pt;
-(void) startFire:(UIView*)view pt:(CGPoint)pt;

-(void) moveTo:(CGPoint)pt;

-(void) stop;
-(void) remove;

@end
