//
//  MainViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 07. 25..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "MainViewController.h"
#import "CWConfiguratorViewController.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;

@end

@implementation MainViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
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

#pragma mark - Navigatiob

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowPlayChooseCW"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[CWConfiguratorViewController class]])
	{
		CWConfiguratorViewController *configuratorVC = (CWConfiguratorViewController*) [segue destinationViewController];
		configuratorVC.isStatisticsView = NO;
	} else if ([segue.identifier compare:@"ShowStatisticsChooseCW"] == NSOrderedSame &&
			   [segue.destinationViewController isKindOfClass:[CWConfiguratorViewController class]])
	{
		CWConfiguratorViewController *configuratorVC = (CWConfiguratorViewController*) [segue destinationViewController];
		configuratorVC.isStatisticsView = YES;
	}
}

@end
