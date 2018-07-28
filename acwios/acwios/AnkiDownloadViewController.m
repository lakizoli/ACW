//
//  AnkiDownloadViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 07. 25..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "AnkiDownloadViewController.h"
#import "ProgressView.h"
#import "Downloader.h"

@interface AnkiDownloadViewController ()

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet ProgressView *progressView;

@property (nonatomic) Downloader *downloader;

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
			NSURL *url = [[navigationAction request] URL];
			
			if (_downloader == nil) {
				_downloader = [Downloader downloadFile:url progressHandler:^(uint64_t pos, uint64_t size) {
					dispatch_async (dispatch_get_main_queue (), ^{
						NSString *progress = [Downloader createDataProgressLabel:pos size:size];
						NSString *label = [NSString stringWithFormat:@"Downloading (%@)...", progress];
						[self->_progressView setLabelContent:label];
						
						if (size > 0) {
							float percent = pos / size;
							[self->_progressView setProgressValue:percent];
						}
					});
				} completionHandler:^(enum DownloadResult resultCode, NSURL *downloadedFile, NSString *fileName) {
					BOOL showFailedAlert = NO;
					switch (resultCode) {
						case DownloadResult_Succeeded: {
							NSFileManager *fileManager = [NSFileManager defaultManager];
							NSURL *docDir = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
							NSString *destFileName;
							if (fileName) {
								destFileName = fileName;
							} else {
								destFileName = [[downloadedFile lastPathComponent] stringByAppendingString:@".apkg"];
							}
							NSURL *destDir = [docDir URLByAppendingPathComponent:destFileName isDirectory:NO];
							if ([fileManager moveItemAtURL:downloadedFile toURL:destDir error:nil] == NO) {
								showFailedAlert = YES;
							}
							break;
						}
						case DownloadResult_Failed:
							showFailedAlert = YES;
							break;
						case DownloadResult_Cancelled:
						default:
							break;
					}
					
					dispatch_async (dispatch_get_main_queue (), ^{
						[self->_progressView setHidden:YES];
						
						if (showFailedAlert) {
							if (downloadedFile) {
								[[NSFileManager defaultManager] removeItemAtURL:downloadedFile error:nil];
							}
							
							UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
																						   message:@"Error occured during download!"
																					preferredStyle:UIAlertControllerStyleAlert];
							
							UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"OK"
																			   style:UIAlertActionStyleDefault
																			 handler:^(UIAlertAction * action) {
																				 [self dismissViewControllerAnimated:YES completion:nil];
																			 }];
							
							[alert addAction:okButton];
							[self presentViewController:alert animated:YES completion:nil];
						} else {
							[self dismissViewControllerAnimated:YES completion:nil];
						}
					});
				}];
				
				[_progressView setButtonLabel:@"Cancel"];
				[_progressView setLabelContent:@"Downloading..."];
				[_progressView setProgressValue:0];
				
				[_progressView setOnButtonPressed:^{
					[self->_downloader cancel];
				}];
				
				[_progressView setHidden:NO];
				
				[_webView setUserInteractionEnabled:NO];
			}
			
			decisionHandler (WKNavigationActionPolicyCancel);
			requestHandled = true;
		}
	}
	
	if (!requestHandled) {
		decisionHandler (WKNavigationActionPolicyAllow);
	}
}

@end
