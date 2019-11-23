//
//  MainViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 07. 25..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "MainViewController.h"
#import "NetLogger.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;

@end

@implementation MainViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[NetLogger logEvent:@"Main_ShowView"];
	
	// Do any additional setup after loading the view, typically from a nib.
	// Set vertical effect
	UIInterpolatingMotionEffect *verticalMotionEffect =	[[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	verticalMotionEffect.minimumRelativeValue = @(-40);
	verticalMotionEffect.maximumRelativeValue = @(40);
	
	// Set horizontal effect
	UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
	horizontalMotionEffect.minimumRelativeValue = @(-40);
	horizontalMotionEffect.maximumRelativeValue = @(40);
	
	// Create group to combine both
	UIMotionEffectGroup *group = [UIMotionEffectGroup new];
	group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
	
	// Add both effects to your view
	[_backgroundView addMotionEffect:group];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
		return [super supportedInterfaceOrientations];
	}
	
	[super supportedInterfaceOrientations];
	return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
		return [super shouldAutorotate];
	}
	
	[super shouldAutorotate];
	return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	if (UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad) {
		return [super preferredInterfaceOrientationForPresentation];
	}
	
	[super preferredInterfaceOrientationForPresentation];
	return UIInterfaceOrientationPortrait;
}

@end
