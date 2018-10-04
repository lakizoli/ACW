//
//  StatisticsViewController.m
//  acwios
//
//  Created by Laki Zoltán on 2018. 10. 04..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "StatisticsViewController.h"

@interface StatisticsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *crosswordName;
@property (weak, nonatomic) IBOutlet CombinedChartView *chart;

@end

@implementation StatisticsViewController {
	NSMutableArray<NSString*> *_stringValues;
}

#pragma mark - Implementation

- (void) setupChart:(NSString*)barLabel
		  lineLabel:(NSString*)lineLabel
		bubbleLabel:(NSString*)bubbleLabel
		  barValues:(NSArray<NSNumber*>*)barValues
		 lineValues:(NSArray<NSNumber*>*)lineValues
	   bubbleValues:(NSArray<NSNumber*>*)bubbleValues
{
	_stringValues = [NSMutableArray<NSString*> new];

	NSMutableArray<BarChartDataEntry*> *barEntries = [NSMutableArray<BarChartDataEntry*> new];
	NSMutableArray<ChartDataEntry*> *lineEntries = [NSMutableArray<ChartDataEntry*> new];
	NSMutableArray<ChartDataEntry*> *bubbleEntries = [NSMutableArray<ChartDataEntry*> new];
	
	for (NSInteger idx = 0; idx < [barValues count]; ++idx) {
		BarChartDataEntry *barEntry = [[BarChartDataEntry alloc] initWithX:idx y:[[barValues objectAtIndex:idx] doubleValue]];
		[barEntries addObject:barEntry];
		
		ChartDataEntry *lineEntry = [[ChartDataEntry alloc] initWithX:idx y:[[lineValues objectAtIndex:idx] doubleValue]];
		[lineEntries addObject:lineEntry];
		
		ChartDataEntry *bubbleEntry = [[ChartDataEntry alloc] initWithX:idx y:[[bubbleValues objectAtIndex:idx] doubleValue]];
		[bubbleEntries addObject:bubbleEntry];
		
		[_stringValues addObject:[NSString stringWithFormat:@"%li", idx + 1]];
	}
	
	BarChartDataSet *barDataSet = [[BarChartDataSet alloc] initWithValues:barEntries label:barLabel];
	BarChartData *barData = [[BarChartData alloc] initWithDataSet:barDataSet];
	
	LineChartDataSet *lineDataSet = [[LineChartDataSet alloc] initWithValues:lineEntries label:lineLabel];
	[lineDataSet setColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
	
	LineChartDataSet *bubbleDataSet = [[LineChartDataSet alloc] initWithValues:bubbleEntries label:bubbleLabel];
	[bubbleDataSet setColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:1]];

	LineChartData *lineData = [[LineChartData alloc] initWithDataSets:@[lineDataSet, bubbleDataSet]];
	
	CombinedChartData *combinedData = [[CombinedChartData alloc] init];
	combinedData.barData = barData;
	combinedData.lineData = lineData;

	ChartYAxis *rightAxis = _chart.rightAxis;
	rightAxis.drawGridLinesEnabled = NO;
	rightAxis.axisMinimum = 0.0; // this replaces startAtZero = YES
	
	ChartYAxis *leftAxis = _chart.leftAxis;
	leftAxis.drawGridLinesEnabled = NO;
	leftAxis.axisMinimum = 0.0; // this replaces startAtZero = YES
	
	ChartXAxis *xAxis = _chart.xAxis;
	xAxis.labelPosition = XAxisLabelPositionBothSided;
	xAxis.axisMinimum = -0.75;
	xAxis.granularity = 1.0;
	xAxis.valueFormatter = self;
	xAxis.axisMaximum = combinedData.xMax + 0.75;

	[_chart setData:combinedData];
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
	
    // Do any additional setup after loading the view.
	NSString *label = [NSString stringWithFormat:@"[%dx%d] (%lu cards) - %@",
					   [_savedCrossword width],
					   [_savedCrossword height],
					   [[_savedCrossword words] count],
					   [_savedCrossword name]];
	[_crosswordName setText:label];
	[_crosswordName setUserInteractionEnabled:NO];
	
	NSArray<Statistics*> *stats = [_savedCrossword loadStatistics];
	
	NSMutableArray<NSNumber*> *barValues = [NSMutableArray<NSNumber*> new];
	NSMutableArray<NSNumber*> *lineValues = [NSMutableArray<NSNumber*> new];
	NSMutableArray<NSNumber*> *bubbleValues = [NSMutableArray<NSNumber*> new];
	for (NSInteger i = 0; i < [stats count]; ++i) {
		Statistics *stat = [stats objectAtIndex:i];
		[barValues addObject:[NSNumber numberWithDouble: stat.fillDuration]];
		[lineValues addObject:[NSNumber numberWithDouble: stat.failCount]];
		[bubbleValues addObject:[NSNumber numberWithDouble: stat.hintCount]];
	}
	
	[self setupChart:@"Solve time in seconds"
		   lineLabel:@"Fail count"
		 bubbleLabel:@"Hint count"
		   barValues:barValues
		  lineValues:lineValues
		bubbleValues:bubbleValues];
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
