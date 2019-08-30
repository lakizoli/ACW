//
//  SUIMainViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2019. 08. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "SUIMainViewController.h"
#import "AnkiDownloadViewController.h"
#import "NetLogger.h"
#import "PackageManager.h"

@interface SUIMainViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelStarting;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;

@end

@implementation SUIMainViewController {
	NSTimer *_timer;
	NSArray<Package*>* _collectedPackages;
	NSDictionary<NSString*, NSArray<SavedCrossword*>*>* _savedCrosswords;
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
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// Start animation
	__block uint32_t animCounter = 0;
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
		if (animCounter >= 6 && self->_collectedPackages != nil) {
			[timer invalidate];
			
			if ([self hasNonEmptyPackage]) { //There are some package already downloaded
				[self performSegueWithIdentifier:@"ShowChooseCW" sender:self];
			} else { // No packages found
				[self performSegueWithIdentifier:@"ShowDownload" sender:self];
			}
		} else {
			++animCounter;
		}
	}];
	
	dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
		self->_collectedPackages = [[PackageManager sharedInstance] collectPackages];
		self->_savedCrosswords = [[PackageManager sharedInstance] collectSavedCrosswords];
	});
}

#pragma mark - Implementation

-(BOOL)hasNonEmptyPackage {
	__block BOOL res = NO;
	[_collectedPackages enumerateObjectsUsingBlock:^(Package * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString *packageKey = [[obj path] lastPathComponent];
		if ([[self->_savedCrosswords objectForKey:packageKey] count] > 0) {
			res = YES;
			*stop = YES;
		}
	}];
	return res;
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowDownload"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[AnkiDownloadViewController class]])
	{
		AnkiDownloadViewController *downloadView = (AnkiDownloadViewController*) segue.destinationViewController;
		[downloadView setBackButtonSegue:@"ShowChooseCW"];
		[downloadView setDoGenerationAfterAnkiDownload:YES];
	}
}

@end
