//
//  SUIMainViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "SUIMainViewController.h"
#import "NetLogger.h"
#import "PackageManager.h"

@interface SUIMainViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelStarting;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;

@end

@implementation SUIMainViewController {
	NSTimer *_timer;
	NSArray<Package*>* _collectedPackages;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[NetLogger logEvent:@"SUIMain_ShowView"];
	
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
	
	// Start animation
	__block uint32_t animCounter = 0;
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
		if (animCounter >= 6 && self->_collectedPackages != nil) {
			[timer invalidate];
			
			if ([self->_collectedPackages count] > 0) { //There are some package already downloaded
			} else { // No packages found
			}
		} else {
			switch (animCounter % 3) {
				case 0:
					[self->_labelStarting setText:@"Starting.  "];
					break;
				case 1:
					[self->_labelStarting setText:@"Starting.. "];
					break;
				case 2:
					[self->_labelStarting setText:@"Starting..."];
					break;
				default:
					break;
			}
			++animCounter;
		}
	}];
	
	dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
		self->_collectedPackages = [[PackageManager sharedInstance] collectPackages];
	});
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
