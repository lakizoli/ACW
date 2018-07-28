//
//  Downloader.mm
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 28..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import "Downloader.h"

@interface Downloader ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionDownloadTask *task;

@end

@implementation Downloader {
	DownloaderProgressHandler _progressHandler;
	DownloaderCompletionHandler _completionHandler;
	uint64_t _size;
	BOOL _cancelled;
}

-(id)initWithProgressHandler:(DownloaderProgressHandler)progressHandler
		   completionHandler:(DownloaderCompletionHandler)completionHandler
{
	self = [super init];
	if (self) {
		_progressHandler = progressHandler;
		_completionHandler = completionHandler;
		_size = 0;
		_cancelled = NO;
	}
	return self;
}

+(Downloader*) downloadFile:(NSURL*)url
	 progressHandler:(DownloaderProgressHandler)progressHandler
   completionHandler:(DownloaderCompletionHandler)completionHandler
{
	Downloader *downloader = [[Downloader alloc] initWithProgressHandler:progressHandler completionHandler:completionHandler];
	
	NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
	downloader.session = [NSURLSession sessionWithConfiguration:config delegate:downloader delegateQueue:nil];
	downloader.task = [downloader.session downloadTaskWithURL:url];
	
	[downloader.task resume];
	
	return downloader;
}

+(NSString*) createDataProgressLabel:(uint64_t)pos size:(uint64_t)size {
	NSString* posItem;
	float posAmount = 0;
	if (pos >= 1024*1024*1024) { //GB
		posItem = @"GB";
		posAmount = pos / 1024.0f / 1024.0f / 1024.0f;
	} else if (pos >= 1024*1024) { //MB
		posItem = @"MB";
		posAmount = pos / 1024.0f / 1024.0f;
	} else if (pos >= 1024) { //KB
		posItem = @"KB";
		posAmount = pos / 1024.0f;
	} else { //B
		posItem = @"B";
		posAmount = pos;
	}
	
	NSString* sizeItem;
	float sizeAmount = 0;
	if (size >= 1024*1024*1024) { //GB
		sizeItem = @"GB";
		sizeAmount = size / 1024.0f / 1024.0f / 1024.0f;
	} else if (size >= 1024*1024) { //MB
		sizeItem = @"MB";
		sizeAmount = size / 1024.0f / 1024.0f;
	} else if (size >= 1024) { //KB
		sizeItem = @"KB";
		sizeAmount = size / 1024.0f;
	} else { //B
		sizeItem = @"B";
		sizeAmount = size;
	}
	
	return [NSString stringWithFormat:@"%.2f%@/%.2f%@", posAmount, posItem, sizeAmount, sizeItem];
}

-(void)cancel {
	_cancelled = YES;
	[_task cancel];
}

#pragma mark - NSURLSessionDelegate

- (void) URLSession:(NSURLSession *)session
	   downloadTask:(NSURLSessionDownloadTask *)downloadTask
	   didWriteData:(int64_t)bytesWritten
  totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
	if (_size <= 0 && totalBytesExpectedToWrite > 0) {
		_size = (uint64_t)totalBytesExpectedToWrite;
	}

	if (_progressHandler && totalBytesWritten > 0) {
		_progressHandler ((uint64_t) totalBytesWritten, _size);
	}
}

-(void) URLSession:(NSURLSession *)session
	  downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
	if (_size <= 0 && expectedTotalBytes > 0) {
		_size = (uint64_t)expectedTotalBytes;
	}
}

-(void) URLSession:(NSURLSession *)session
	  downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
	if (_completionHandler) {
		NSString *fileName = [[downloadTask response] suggestedFilename];
		if ([fileName caseInsensitiveCompare:@"unknown"] == NSOrderedSame) {
			fileName = nil;
		}
		_completionHandler (DownloadResult_Succeeded, location, fileName);
	}
}

-(void) URLSession:(NSURLSession *)session
			  task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
	if (_completionHandler && error) {
		enum DownloadResult resCode = _cancelled ? DownloadResult_Cancelled : DownloadResult_Failed;
		_completionHandler (resCode, nil, nil);
	}
}

@end
