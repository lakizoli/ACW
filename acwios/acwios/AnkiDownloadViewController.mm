//
//  AnkiDownloadViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 07. 25..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "AnkiDownloadViewController.h"
#import "ProgressView.h"

@interface AnkiDownloadViewController ()

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet ProgressView *progressView;

@end

@implementation AnkiDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Init web view
	[[self webView] setNavigationDelegate:self];
	
    //Browse anki sheets site
	NSURL* url = [NSURL URLWithString:@"https://ankiweb.net/shared/decks/"];
	NSURLRequest* req = [NSURLRequest requestWithURL:url];
	[[self webView] loadRequest:req];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Event handlers

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Web navigation

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	//Catch package download
	bool requestHandled = false;
	if (navigationAction.navigationType == WKNavigationTypeFormSubmitted ||
		navigationAction.navigationType == WKNavigationTypeFormResubmitted)
	{
		NSString* urlContent = [[[navigationAction request] URL] absoluteString];
		if ([urlContent localizedCaseInsensitiveContainsString:@"download"] == YES &&
			[urlContent localizedCaseInsensitiveContainsString:@"?"] == YES)
		{
			[_progressView setButtonLabel:@"Cancel"];
			[_progressView setLabelContent:@"Downloading package..."];
			[_progressView setProgressValue:0];
			[_progressView setHidden:NO];
			
			NSLog (@"navigating to url: %@", [[navigationAction request] URL]);
			//NSLog (@"navigation action: %@", navigationAction);
			
			decisionHandler (WKNavigationActionPolicyCancel);
			requestHandled = true;
		}
	}
	
	if (!requestHandled) {
		decisionHandler (WKNavigationActionPolicyAllow);
	}
}

@end
