//
//  AnkiDownloadViewController.h
//  acwios
//
//  Created by Laki, Zoltan on 2018. 07. 25..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface AnkiDownloadViewController : UIViewController<UITabBarDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WKNavigationDelegate>

- (void) setBackButtonSegue:(NSString*)segueID;
- (void) setDoGenerationAfterAnkiDownload:(BOOL)doGenerationAfterAnkiDownload;

@end
