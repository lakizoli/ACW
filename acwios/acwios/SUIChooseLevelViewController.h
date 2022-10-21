//
//  SUIChooseLevelViewController.h
//  acwios
//
//  Created by Zoli on 2022. 10. 20..
//  Copyright © 2022. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Package.h"

NS_ASSUME_NONNULL_BEGIN

@interface SUIChooseLevelViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong) Package *currentPackage;
@property (assign) NSUInteger currentCrosswordIndex;
@property (strong) NSArray<SavedCrossword*> *allSavedCrossword;

@end

NS_ASSUME_NONNULL_END
