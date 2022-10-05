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

@interface DownloadCell : UICollectionViewCell

//@property (weak, nonatomic) IBOutlet UIImageView *leftTopImage;
//@property (weak, nonatomic) IBOutlet UIImageView *rightTopImage;
@property (weak, nonatomic) IBOutlet UITextView *leftText;
//@property (weak, nonatomic) IBOutlet UIImageView *centerImage;
@property (weak, nonatomic) IBOutlet UITextView *rightText;
//@property (weak, nonatomic) IBOutlet UIImageView *leftBottomImage;
//@property (weak, nonatomic) IBOutlet UIImageView *rightBottomImage;

@end

@implementation DownloadCell

@end

@interface AnkiDownloadViewController ()

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet ProgressView *progressView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (nonatomic) Downloader *downloader;
@property (nonatomic) NSMutableArray<NetPackConfigItem*> *packageConfigs;

@end

@implementation AnkiDownloadViewController {
	NSString *_backButtonSegueID;
	BOOL _doGenerationAfterAnkiDownload;
	Package *_package;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		_doGenerationAfterAnkiDownload = NO;
		_package = nil;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		_doGenerationAfterAnkiDownload = NO;
		_package = nil;
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
    
    //Init collection view
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    
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
            [self->_collectionView reloadData];
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
    [_progressView setButtonLabel:NSLocalizedString (@"cancel", @"")];
    [_progressView setLabelContent:NSLocalizedString (@"downloading", @"")];
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
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString (@"error_title", @"")
                                                                           message:NSLocalizedString (@"download_error", @"")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* okButton = [UIAlertAction actionWithTitle:NSLocalizedString (@"ok", @"")
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
                        self->_package = obj;
                        *stop = YES;
                    }
                }];
                
                if (self->_package != nil && [self->_package.decks count] > 0) {
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
        if (size != nil) {
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
        if (size != nil) {
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
    [_tableView setHidden:YES]; //<<<<<
    [_collectionView setHidden:NO];
    
    //Refresh list of packages
    [_tableView reloadData];
    [_collectionView reloadData];
}

- (void)selectSearch {
    //Show web view
    [_tableView setHidden:YES]; //<<<<<
    [_collectionView setHidden:YES];
    [_webView setHidden:NO];
    
    //Browse anki sheets site
    NSURL* url = [NSURL URLWithString:@"https://ankiweb.net/shared/decks/"];
    NSURLRequest* req = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:req];
}

- (NSString*) localizeLabel:(NSString*)label {
    NSRange sep1 = [label rangeOfString:@" -> "];
    if (sep1.location == NSNotFound) {
        return label;
    }
    
    NSRange sep2 = [label rangeOfString:@" ("];
    if (sep2.location == NSNotFound) {
        return label;
    }
    
    NSRange wordRange = [label rangeOfString:@"words"];
    NSString *key1 = [label substringToIndex:sep1.location];
    
    NSRange key2Range = NSMakeRange (sep1.location + sep1.length, sep2.location - sep1.location - sep1.length);
    NSString *key2 = [label substringWithRange:key2Range];
    
    label = [label stringByReplacingCharactersInRange:wordRange withString:NSLocalizedString (@"words", @"")];
    label = [label stringByReplacingCharactersInRange:key2Range withString:NSLocalizedString (key2, @"")];
    label = [label stringByReplacingCharactersInRange:NSMakeRange (0, sep1.location) withString:NSLocalizedString (key1, @"")];
    return label;
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
        [genView setPackage: _package];
        [genView setDecks:_package.decks];
    }
}

#pragma mark - Event handlers

- (IBAction)backButtonPressed:(id)sender {
    [self dismissView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if ([[_tabBar selectedItem] tag] == 1) {
        [self->_tableView reloadData];
        [self->_collectionView reloadData];
    }
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
    NSString *label = [self localizeLabel:configItem.label];
    [[cell textLabel] setText:label];
    
    //Add border to cell
    for (UIView* view in cell.contentView.subviews) {
        if (view.tag == 100) {
            [view removeFromSuperview];
            break;
        }
    }
    
    if (indexPath.row % 2 == 1) {
        UIView* bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.bounds.size.height - 1, self.view.bounds.size.width, 1)];
        bottomLineView.backgroundColor = [UIColor blackColor];
        bottomLineView.tag = 100;
        [cell.contentView addSubview:bottomLineView];
    }
    
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

#pragma mark - Collection View delegates

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [_packageConfigs count];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
	NSString *reuseID = @"NetPackageCollectionCell";
	DownloadCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
	if (cell == nil) {
		cell = [[DownloadCell alloc] init];
	}
	
	NetPackConfigItem *configItem = [_packageConfigs objectAtIndex:indexPath.row];
	NSString *label = [self localizeLabel:configItem.label];
//	[[cell textLabel] setText:label];
	[[cell leftText] setText:label];
	[[cell rightText] setText:label];
	
//	[[cell leftTopImage] setHidden:YES];
//	[[cell leftBottomImage] setHidden:YES];
//	[[cell rightTopImage] setHidden:YES];
//	[[cell rightBottomImage] setHidden:YES];
//	[[cell centerImage] setHidden:YES];

	//Add border to cell
//    for (UIView* view in cell.contentView.subviews) {
//        if (view.tag == 100) {
//            [view removeFromSuperview];
//            break;
//        }
//    }

//    if (indexPath.row % 2 == 1) {
//        UIView* bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.bounds.size.height - 1, self.view.bounds.size.width, 1)];
//        bottomLineView.backgroundColor = [UIColor blackColor];
//        bottomLineView.tag = 100;
//        [cell.contentView addSubview:bottomLineView];
//    }
	
	if (indexPath.row % 2 == 1) {
		[cell.contentView setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
	} else {
		[cell.contentView setBackgroundColor:[UIColor systemBackgroundColor]];
	}
	
	return cell;
}

//TODO: tweak sizes for phone either...

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake (100, 100, 100, 100);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return 150;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 150;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return CGSizeMake (200, 200);
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
