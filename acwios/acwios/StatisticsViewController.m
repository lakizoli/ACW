//
//  StatisticsViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 10. 04..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "StatisticsViewController.h"
#import <Flurry.h>

@interface StatisticsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *crosswordName;
@property (weak, nonatomic) IBOutlet BarChartView *chart;
@property (weak, nonatomic) IBOutlet BarChartView *chart2;
@property (weak, nonatomic) IBOutlet BarChartView *chart3;

@end

@implementation StatisticsViewController {
	NSMutableArray<NSString*> *_stringValues;
}

#pragma mark - Implementation

- (void) setupChart:(BarChartView*)chart label:(NSString*)label values:(NSArray<NSNumber*>*)values {
	_stringValues = [NSMutableArray<NSString*> new];

	NSMutableArray<BarChartDataEntry*> *barEntries = [NSMutableArray<BarChartDataEntry*> new];
	for (NSInteger idx = 0; idx < [values count]; ++idx) {
		BarChartDataEntry *barEntry = [[BarChartDataEntry alloc] initWithX:idx y:[[values objectAtIndex:idx] doubleValue]];
		[barEntries addObject:barEntry];
		
		[_stringValues addObject:[NSString stringWithFormat:@"%li", idx + 1]];
	}
	
	BarChartDataSet *barDataSet = [[BarChartDataSet alloc] initWithValues:barEntries label:label];
	[barDataSet setColor:[UIColor colorWithRed:40.0 / 255.0 green:80.0 / 255.0 blue:80.0 / 255.0 alpha:1]];
	
	BarChartData *barData = [[BarChartData alloc] initWithDataSet:barDataSet];
	
	ChartYAxis *rightAxis = chart.rightAxis;
	rightAxis.drawGridLinesEnabled = NO;
	rightAxis.axisMinimum = 0.0; // this replaces startAtZero = YES
	
	ChartYAxis *leftAxis = chart.leftAxis;
	leftAxis.drawGridLinesEnabled = NO;
	leftAxis.axisMinimum = 0.0; // this replaces startAtZero = YES
	
	ChartXAxis *xAxis = chart.xAxis;
	xAxis.labelPosition = XAxisLabelPositionBothSided;
	xAxis.axisMinimum = -0.75;
	xAxis.granularity = 1.0;
	xAxis.valueFormatter = self;
	xAxis.axisMaximum = barData.xMax + 0.75;

	[chart setData:barData];
	[chart setBackgroundColor:[UIColor colorWithRed:213.0 / 255.0 green:224.0 / 255.0 blue:230.0 / 255.0 alpha:1]];
}

#pragma mark - IAxisValueFormatter

- (NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis {
	return _stringValues[(int)value % _stringValues.count];
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Events

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[Flurry logEvent:@"Statistics_ShowView"];
	
    // Do any additional setup after loading the view.
	NSString *label = [NSString stringWithFormat:@"[%dx%d] (%lu cards) - %@",
					   [_savedCrossword width],
					   [_savedCrossword height],
					   [[_savedCrossword words] count],
					   [_savedCrossword name]];
	[_crosswordName setText:label];
	[_crosswordName setUserInteractionEnabled:NO];
	
	NSArray<Statistics*> *stats = [_savedCrossword loadStatistics];
	
	NSMutableArray<NSNumber*> *timeValues = [NSMutableArray<NSNumber*> new];
	NSMutableArray<NSNumber*> *failValues = [NSMutableArray<NSNumber*> new];
	NSMutableArray<NSNumber*> *hintValues = [NSMutableArray<NSNumber*> new];
	for (NSInteger i = 0; i < [stats count]; ++i) {
		Statistics *stat = [stats objectAtIndex:i];
		[timeValues addObject:[NSNumber numberWithDouble: stat.fillDuration]];
		[failValues addObject:[NSNumber numberWithDouble: stat.failCount]];
		[hintValues addObject:[NSNumber numberWithDouble: stat.hintCount]];
	}
	
	[self setupChart:_chart label:@"Solve time in seconds" values:timeValues];
	[self setupChart:_chart2 label:@"Fail count" values:failValues];
	[self setupChart:_chart3 label:@"Hint count" values:hintValues];
}

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
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
