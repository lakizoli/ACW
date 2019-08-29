//
//  CWGeneratorViewController.h
//  acwios
//
//  Created by Laki, Zoltan on 2018. 08. 03..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Package.h"

@interface CWGeneratorViewController : UIViewController<UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) NSArray<Deck*> *decks;
@property (nonatomic, assign) BOOL fullGeneration;

@end
