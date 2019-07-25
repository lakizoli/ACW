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
#import "NetPackConfig.h"

#define NETPACK_CFG_ID				@"1DRdHyx9Pj6XtdPrKlpBmGo4BMz9ecbUR"
#define GOOGLE_DRIVE_URL(fileID)	@"https://drive.google.com/uc?id=" fileID @"&export=download"

@interface AnkiDownloadViewController ()

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet ProgressView *progressView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (nonatomic) Downloader *downloader;
@property (nonatomic) NSMutableArray<NSString*> *packageNames;
@property (nonatomic) NSMutableArray<NSString*> *packageFileIDs;

@end

@implementation AnkiDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Init tab bar
	[[self tabBar] setDelegate:self];
	[[self tabBar] setSelectedItem:[[[self tabBar] items] firstObject]];
	
	//Init web view
	[[self webView] setNavigationDelegate:self];
	
	//Download list of packages
	NSURL *packUrl = [NSURL URLWithString:GOOGLE_DRIVE_URL(NETPACK_CFG_ID)];
	[self downloadFileFromGoogleDrive:packUrl contentHandler:^(NSURL *downloadedFile, NSString* fileName) {
		NetPackConfig *netPackConfig = [[NetPackConfig alloc] initWithURL:downloadedFile];
		
		self->_packageNames = [NSMutableArray new];
		self->_packageFileIDs = [NSMutableArray new];
		
		[netPackConfig enumerateLanguagesWihtBlock:^(NSString * _Nonnull label, NSString * _Nonnull fileID) {
			[self->_packageNames addObject:label];
			[self->_packageFileIDs addObject:fileID];
		}];
		
		if ([self->_packageNames count] != [self->_packageFileIDs count]) {
			self->_packageNames = nil;
			self->_packageFileIDs = nil;
		}
		
		dispatch_async (dispatch_get_main_queue (), ^{
			[[self tableView] reloadData];
		});
	} progressHandler:nil];
	
	//Select default view
	[self selectTopRated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSURL*)getURLForMovedContentOnGoogleDrive:(NSURL*)filePath {
	NSUInteger fileSize = 1000000;
	NSDictionary<NSFileAttributeKey, id> *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[filePath path] error:nil];
	if (attrs) {
		NSNumber *size = [attrs objectForKey:NSFileSize];
		if (size) {
			fileSize = [size integerValue];
		}
	}
	
	if (fileSize >= 10000) { //If file is too big, then cannot be moving desc
		return nil;
	}
	
	NSString *content = [NSString stringWithContentsOfURL:filePath encoding:NSUTF8StringEncoding error:nil];
	if (content) {
		NSRange range = [content rangeOfString:@"<HEAD>"];
		if (range.location != NSNotFound) {
			range = [content rangeOfString:@"Moved"];
			if (range.location != NSNotFound) {
				range = [content rangeOfString:@"href" options:NSCaseInsensitiveSearch];
				if (range.location != NSNotFound) {
					content = [content substringFromIndex:range.location + range.length];
					range = [content rangeOfString:@"\""];
					if (range.location != NSNotFound) {
						content = [content substringToIndex:range.location];
						return [NSURL URLWithString:content];
					}
				}
			}
		}
	}
	
	return nil;
}

- (void)downloadFileFromGoogleDrive:(NSURL*)url
					 contentHandler:(void(^)(NSURL *downloadedFile, NSString* fileName))contentHandler
					progressHandler:(void(^)(uint64_t pos, uint64_t size))progressHandler {
	_downloader = [Downloader downloadFile:url
						   progressHandler:progressHandler
						 completionHandler:^(enum DownloadResult resultCode, NSURL *downloadedFile, NSString *fileName)
	{
		switch (resultCode) {
			case DownloadResult_Succeeded: {
				NSURL* movedContentURL = [self getURLForMovedContentOnGoogleDrive:downloadedFile];
				if (movedContentURL) { //Moved content on the Google Drive
					[self downloadFileFromGoogleDrive:movedContentURL contentHandler:contentHandler progressHandler:progressHandler];
				} else { //Full file downloaded
					if (contentHandler) {
						contentHandler (downloadedFile, fileName);
					}
					
//					if (dest) {
//						NSError *error = nil;
//						if ([[NSFileManager defaultManager] moveItemAtURL:downloadedFile toURL:dest error:&error] != YES) {
//							NSLog (@"Cannot move downloaded file to the destination: %@", dest);
//						}
//					}
				}
				break;
			}
			case DownloadResult_Failed:
				break;
			case DownloadResult_Cancelled:
			default:
				break;
		}
	}];
}

- (void)selectTopRated {
	//Show table view
	[[self webView] setHidden:YES];
	[[self tableView] setHidden:NO];
	
	//Download list of packages
}

- (void)selectSearch {
	//Show web view
	[[self tableView] setHidden:YES];
	[[self webView] setHidden:NO];
	
	//Browse anki sheets site
	NSURL* url = [NSURL URLWithString:@"https://ankiweb.net/shared/decks/"];
	NSURLRequest* req = [NSURLRequest requestWithURL:url];
	[[self webView] loadRequest:req];
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Event handlers

- (IBAction)backButtonPressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Tab Bar navigation

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
	switch ([item tag]) {
		case 1: //Top Rated
			[self selectTopRated];
			break;
		case 2: //Search
			[self selectSearch];
			break;
		default:
			break;
	}
}

#pragma mark - TableView delegate

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
						NSString *label = [NSString stringWithFormat:@"%@", progress];
						[self->_progressView setLabelContent:label];
						
						if (size > 0) {
							float percent = (float)pos / (float)size;
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
