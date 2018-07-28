//
//  Downloader.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 28..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>

enum DownloadResult {
	DownloadResult_Failed,
	DownloadResult_Cancelled,
	DownloadResult_Succeeded
};

typedef void (^DownloaderProgressHandler) (uint64_t pos, uint64_t size);
typedef void (^DownloaderCompletionHandler) (enum DownloadResult resultCode, NSURL *downloadedFile, NSString *fileName);

@interface Downloader : NSObject<NSURLSessionDownloadDelegate>

+(Downloader*) downloadFile:(NSURL*)url
	 progressHandler:(DownloaderProgressHandler)progressHandler
   completionHandler:(DownloaderCompletionHandler)completionHandler;

+(NSString*) createDataProgressLabel:(uint64_t)pos size:(uint64_t)size;

-(void)cancel;

@end
