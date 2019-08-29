//
//  AnkiDownloadViewController.m
//  acwios
//
//  Created by Laki, Zoltan on 2018. 07. 25..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "AnkiDownloadViewController.h"
#import "CWGeneratorViewController.h"
#import "ProgressView.h"
#import "Downloader.h"
#import "NetPackConfig.h"
#import "PackageManager.h"
#import "NetLogger.h"

#define NETPACK_CFG_ID				@"1DRdHyx9Pj6XtdPrKlpBmGo4BMz9ecbUR"

@interface AnkiDownloadViewController ()

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet ProgressView *progressView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (nonatomic) Downloader *downloader;
@property (nonatomic) NSMutableArray<NetPackConfigItem*> *packageConfigs;

@end

@implementation AnkiDownloadViewController {
	NSString *_backButtonSegueID;
	BOOL _doGenerationAfterAnkiDownload;
	NSArray<Deck*> *_decks;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		_doGenerationAfterAnkiDownload = NO;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		_doGenerationAfterAnkiDownload = NO;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[NetLogger logEvent:@"Obtain_ShowView"];
	
	//Init tab bar
	[_tabBar setDelegate:self];
	[_tabBar setSelectedItem:[[_tabBar items] firstObject]];
	
	//Init web view
	[_webView setNavigationDelegate:self];
	
	//Init table view
	[_tableView setDataSource:self];
	[_tableView setDelegate:self];
	
	//Download list of packages
	NSURL *packUrl = [self getDownloadLinkForGoogleDrive:NETPACK_CFG_ID];
	[self downloadFileFromGoogleDrive:packUrl handleEnd:NO contentHandler:^(NSURL *downloadedFile, NSString* fileName) {
		NetPackConfig *netPackConfig = [[NetPackConfig alloc] initWithURL:downloadedFile];
		
		self->_packageConfigs = [NSMutableArray new];
		
		[netPackConfig enumerateLanguagesWihtBlock:^(NetPackConfigItem * _Nonnull configItem) {
			[self->_packageConfigs addObject:configItem];
		}];
		
		dispatch_async (dispatch_get_main_queue (), ^{
			[self->_tableView reloadData];
		});
	} progressHandler:nil];
	
	//Select default view
	[self selectTopRated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showProgressView {
	[_progressView setButtonLabel:@"Cancel"];
	[_progressView setLabelContent:@"Downloading..."];
	[_progressView setProgressValue:0];
	
	[_progressView setOnButtonPressed:^{
		[self->_downloader cancel];
	}];
	
	[_progressView setHidden:NO];
}

-(void)updateProgress:(uint64_t)pos size:(uint64_t)size {
	dispatch_async (dispatch_get_main_queue (), ^{
		NSString *progress = [Downloader createDataProgressLabel:pos size:size];
		NSString *label = [NSString stringWithFormat:@"%@", progress];
		[self->_progressView setLabelContent:label];
		
		if (size > 0) {
			float percent = (float)pos / (float)size;
			[self->_progressView setProgressValue:percent];
		}
	});
}

- (void) setBackButtonSegue:(NSString*)segueID {
	_backButtonSegueID = segueID;
}

- (void) setDoGenerationAfterAnkiDownload:(BOOL)doGenerationAfterAnkiDownload {
	_doGenerationAfterAnkiDownload = doGenerationAfterAnkiDownload;
}

-(void)dismissView {
	if (_backButtonSegueID) {
		[self performSegueWithIdentifier:_backButtonSegueID sender:self];
	} else {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

-(void)endOfDownload:(BOOL)showFailedAlert downloadedFile:(NSURL*)downloadedFile doGen:(BOOL)doGen packageName:(NSString*)packageNameFull {
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
																 [self dismissView];
															 }];
			
			[alert addAction:okButton];
			[self presentViewController:alert animated:YES completion:nil];
		} else {
			if (doGen) {
				NSString *packageName = packageNameFull;
				NSString *ext = [packageNameFull pathExtension];
				if ([ext length] > 0) {
					packageName = [packageNameFull substringToIndex:[packageNameFull length] - [ext length] - 1];
				}
				
				NSArray<Package*> *packages = [[PackageManager sharedInstance] collectPackages];
				
				[packages enumerateObjectsUsingBlock:^(Package * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
					NSString *testPackageName = [[obj path] lastPathComponent];
					if ([testPackageName compare:packageName] == NSOrderedSame) {
						self->_decks = [obj decks];
						*stop = YES;
					}
				}];
				
				if ([self->_decks count] > 0) {
					[self performSegueWithIdentifier:@"ShowGen" sender:self];
				} else {
					[self dismissView];
				}
			} else {
				[self dismissView];
			}
		}
	});
}

- (NSURL*)getDownloadLinkForGoogleDrive:(NSString*)fileID {
	NSString *link = [NSString stringWithFormat:@"https://drive.google.com/uc?id=%@&export=download", fileID];
	return [NSURL URLWithString:link];
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
		NSRange range = [content rangeOfString:@"<head>" options:NSCaseInsensitiveSearch];
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

- (NSURL*)getURLForConfirmedContentOnGoogleDrive:(NSURL*)filePath origURL:(NSURL*)origURL {
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
		NSRange range = [content rangeOfString:@"<head>" options:NSCaseInsensitiveSearch];
		if (range.location != NSNotFound) {
			range = [content rangeOfString:@"export=download&amp;confirm=" options:NSCaseInsensitiveSearch];
			if (range.location != NSNotFound) {
				content = [content substringFromIndex:range.location + range.length];
				range = [content rangeOfString:@"&amp;"];
				if (range.location != NSNotFound) {
					content = [content substringToIndex:range.location];
					NSString *urlString = [origURL absoluteString];
					urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&confirm=%@", content]];
					return [NSURL URLWithString:urlString];
				}
			}
		}
	}
	
	return nil;
}

- (void)downloadFileFromGoogleDrive:(NSURL*)url
						  handleEnd:(BOOL)handleEnd
					 contentHandler:(void(^)(NSURL *downloadedFile, NSString* fileName))contentHandler
					progressHandler:(void(^)(uint64_t pos, uint64_t size))progressHandler {
	_downloader = [Downloader downloadFile:url
						   progressHandler:progressHandler
						 completionHandler:^(enum DownloadResult resultCode, NSURL *downloadedFile, NSString *fileName)
	{
		BOOL showFailedAlert = NO;
		switch (resultCode) {
			case DownloadResult_Succeeded: {
				NSURL* movedContentURL = [self getURLForMovedContentOnGoogleDrive:downloadedFile];
				if (movedContentURL) { //Moved content on the Google Drive
					[self downloadFileFromGoogleDrive:movedContentURL
											handleEnd:handleEnd
									   contentHandler:contentHandler
									  progressHandler:progressHandler];
					return;
				}
				
				NSURL *confirmURL = [self getURLForConfirmedContentOnGoogleDrive:downloadedFile origURL:url];
				if (confirmURL) {
					[self downloadFileFromGoogleDrive:confirmURL
											handleEnd:handleEnd
									   contentHandler:contentHandler
									  progressHandler:progressHandler];
					return;
				}
				
				//Full file downloaded
				if (contentHandler) {
					contentHandler (downloadedFile, fileName);
				}
				break;
			}
			case DownloadResult_Failed:
				showFailedAlert = YES;
				[NetLogger logEvent:@"Obtain_NetPackage_Failed" withParameters:@{ @"url" : [url absoluteString] }];
				break;
			case DownloadResult_Cancelled:
				[NetLogger logEvent:@"Obtain_NetPackage_Cancelled" withParameters:@{ @"url" : [url absoluteString] }];
				break;
			default:
				[NetLogger logEvent:@"Obtain_NetPackage_Unknown" withParameters:@{ @"url" : [url absoluteString] }];
				break;
		}
		
		if (handleEnd) {
			[self endOfDownload:showFailedAlert downloadedFile:downloadedFile doGen:NO packageName:nil];
		}
	}];
}

- (void)selectTopRated {
	//Show table view
	[_webView setHidden:YES];
	[_tableView setHidden:NO];
	
	//Refresh list of packages
	[_tableView reloadData];
}

- (void)selectSearch {
	//Show web view
	[_tableView setHidden:YES];
	[_webView setHidden:NO];
	
	//Browse anki sheets site
	NSURL* url = [NSURL URLWithString:@"https://ankiweb.net/shared/decks/"];
	NSURLRequest* req = [NSURLRequest requestWithURL:url];
	[_webView loadRequest:req];
}

#pragma mark - Appearance

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier compare:@"ShowGen"] == NSOrderedSame &&
		[segue.destinationViewController isKindOfClass:[CWGeneratorViewController class]])
	{
		CWGeneratorViewController *genView = (CWGeneratorViewController*) segue.destinationViewController;
		[genView setDecks:_decks];
		[genView setFullGeneration:YES];
	}
}

#pragma mark - Event handlers

- (IBAction)backButtonPressed:(id)sender {
	[self dismissView];
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

#pragma mark - TableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_packageConfigs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *reuseID = @"NetPackageCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseID];
	}
	
	NetPackConfigItem *configItem = [_packageConfigs objectAtIndex:indexPath.row];
	[[cell textLabel] setText:configItem.label];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	__block NetPackConfigItem *configItem = [_packageConfigs objectAtIndex:indexPath.row];
	NSURL *url = [self getDownloadLinkForGoogleDrive:configItem.fileID];
	
	[NetLogger logEvent:@"Obtain_NetPackage_Selected" withParameters:@{ @"label" : configItem.label, @"url" : [url absoluteString] }];

	[self downloadFileFromGoogleDrive:url
							handleEnd:YES
					   contentHandler:^(NSURL *downloadedFile, NSString *fileName)
	{
		[NetLogger logEvent:@"Obtain_NetPackage_Downloaded" withParameters:@{ @"label" : configItem.label, @"url" : [url absoluteString], @"fileName" : fileName }];

		//Unzip downloaded file to packages
		[[PackageManager sharedInstance] unzipDownloadedPackage:downloadedFile packageName:[fileName stringByDeletingPathExtension]];
	} progressHandler:^(uint64_t pos, uint64_t size) {
		if (size <= 0) {
			size = configItem.size;
		}

		[self updateProgress:pos size:size];
	}];

	[self showProgressView];
	
	[_tableView setUserInteractionEnabled:NO];
	[_tabBar setUserInteractionEnabled:NO];
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
			
			[NetLogger logEvent:@"Obtain_AnkiPackage_Selected" withParameters:@{ @"url" : [url absoluteString] }];

			_downloader = [Downloader downloadFile:url progressHandler:^(uint64_t pos, uint64_t size) {
				[self updateProgress:pos size:size];
			} completionHandler:^(enum DownloadResult resultCode, NSURL *downloadedFile, NSString *fileName) {
				[NetLogger logEvent:@"Obtain_AnkiPackage_Downloaded" withParameters:@{ @"url" : [url absoluteString],
																					   @"fileName" : [fileName length] > 0 ? fileName : @"null",
																					@"resultCode" : [NSNumber numberWithInt:resultCode] }];

				NSString *destFileName;
				BOOL doGen = NO;
				BOOL showFailedAlert = NO;
				switch (resultCode) {
					case DownloadResult_Succeeded: {
						NSFileManager *fileManager = [NSFileManager defaultManager];
						NSURL *docDir = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
						if (fileName) {
							destFileName = fileName;
						} else {
							destFileName = [[downloadedFile lastPathComponent] stringByAppendingString:@".apkg"];
						}
						NSURL *destDir = [docDir URLByAppendingPathComponent:destFileName isDirectory:NO];
						[fileManager removeItemAtURL:destDir error:nil];
						if ([fileManager moveItemAtURL:downloadedFile toURL:destDir error:nil] == NO) { //Failed move
							showFailedAlert = YES;
						} else { //Succeeded move
							doGen = self->_doGenerationAfterAnkiDownload;
						}
						break;
					}
					case DownloadResult_Failed:
						showFailedAlert = YES;
						[NetLogger logEvent:@"Obtain_AnkiPackage_Failed" withParameters:@{ @"url" : [url absoluteString] }];
						break;
					case DownloadResult_Cancelled:
						[NetLogger logEvent:@"Obtain_AnkiPackage_Cancelled" withParameters:@{ @"url" : [url absoluteString] }];
						break;
					default:
						[NetLogger logEvent:@"Obtain_AnkiPackage_Unknown" withParameters:@{ @"url" : [url absoluteString] }];
						break;
				}
				
				[self endOfDownload:showFailedAlert downloadedFile:downloadedFile doGen:doGen packageName:destFileName];
			}];
			
			[self showProgressView];
			
			[_webView setUserInteractionEnabled:NO];
			[_tabBar setUserInteractionEnabled:NO];
			
			decisionHandler (WKNavigationActionPolicyCancel);
			requestHandled = true;
		}
	}
	
	if (!requestHandled) {
		decisionHandler (WKNavigationActionPolicyAllow);
	}
}

@end
