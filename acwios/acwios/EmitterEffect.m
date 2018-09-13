//
//  EmitterEffect.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 09. 13..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "EmitterEffect.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
//Info taken from here: https://www.raywenderlich.com/2989-uikit-particle-systems-in-ios-5-tutorial
////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation EmitterEffect {
	CAEmitterLayer *_emitter;
}

-(void) startSparkler:(UIView*)view pt:(CGPoint)pt {
	float multiplier = 0.25f;
	
//	CGPoint pt = [[touches anyObject] locationInView:self];
	
	//Create the emitter layer
	_emitter = [CAEmitterLayer layer];
	_emitter.emitterPosition = pt;
	_emitter.emitterMode = kCAEmitterLayerOutline;
	_emitter.emitterShape = kCAEmitterLayerCircle;
	_emitter.renderMode = kCAEmitterLayerAdditive;
	_emitter.emitterSize = CGSizeMake(100 * multiplier, 0);
	
	//Create the emitter cell
	CAEmitterCell* particle = [CAEmitterCell emitterCell];
	particle.emissionLongitude = M_PI;
	particle.birthRate = multiplier * 1000.0;
	particle.lifetime = multiplier;
	particle.lifetimeRange = multiplier * 0.35;
	particle.velocity = 180;
	particle.velocityRange = 130;
	particle.emissionRange = 1.1;
	particle.scaleSpeed = 1.0; // was 0.3
	particle.color = [[[UIColor purpleColor] colorWithAlphaComponent:0.5f] CGColor];
	particle.contents = (__bridge id)([UIImage imageNamed:@"arrow-back"].CGImage); //spark.png
	particle.name = @"particle";
	
	_emitter.emitterCells = [NSArray arrayWithObject:particle];
	[view.layer addSublayer:_emitter];
}

-(void) startFireWorks:(UIView*)view pt:(CGPoint)pt {
	float multiplier = 0.25f;
	
	//Create the emitter layer
	_emitter = [CAEmitterLayer layer];
	_emitter.emitterPosition = pt;
	_emitter.emitterMode = kCAEmitterLayerOutline;
	_emitter.emitterShape = kCAEmitterLayerCircle;
	_emitter.renderMode = kCAEmitterLayerAdditive;
	_emitter.emitterSize = CGSizeMake(15, 15);

	CAEmitterCell* fire = [CAEmitterCell emitterCell];
	fire.birthRate = multiplier * 1000.0;
	fire.lifetime = 2.0;
	fire.lifetimeRange = 0.5;
	fire.color = [[UIColor colorWithRed:0.8 green:0.4 blue:0.2 alpha:0.6] CGColor];
	fire.contents = (__bridge id)([UIImage imageNamed:@"arrow-back"].CGImage); //star_icon.png
	[fire setName:@"fire"];
	
	fire.velocity = 180;
	fire.velocityRange = 120;
	fire.emissionRange = M_PI * 2.0f;
	
	fire.scaleSpeed = 0.1;
	fire.spin = 0.5;
	
	//add the cell to the layer and we're done
	_emitter.emitterCells = [NSArray arrayWithObject:fire];
	[view.layer addSublayer:_emitter];
	
	dispatch_after (dispatch_time (DISPATCH_TIME_NOW, (int64_t)(100 * 1000000)), dispatch_get_main_queue (), ^{
		[self stop];
	});
}

-(void) moveTo:(CGPoint)pt {
//	CGPoint pt = [[touches anyObject] locationInView:self];
	
	// Disable implicit animations
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	_emitter.emitterPosition = pt;
	[CATransaction commit];
}

-(void) stop {
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	_emitter.birthRate = 0;
	[CATransaction commit];
}

-(void) remove {
	[_emitter removeFromSuperlayer];
	_emitter = nil;
}

@end
