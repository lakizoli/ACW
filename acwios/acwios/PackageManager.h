//
//  PackageManager.h
//  acwios
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Package.h"

@interface PackageManager : NSObject

+(PackageManager*) sharedInstance;

-(NSArray<Package*>*)collectPackages;
-(NSDictionary<NSString*, NSArray<SavedCrossword*>*>*)collectSavedCrosswords;
-(GeneratorInfo*)collectGeneratorInfo:(NSArray<Deck*>*)decks;
-(void)reloadUsedWords:(NSURL*)packagePath info:(GeneratorInfo*)info;

-(NSString*)trimQuestionField:(NSString*)questionField;
-(NSString*)trimSolutionField:(NSString*)solutionField;
-(BOOL)generateWithInfo:(GeneratorInfo*)info progressCallback:(void(^)(float, BOOL*))progressCallback;

@end
