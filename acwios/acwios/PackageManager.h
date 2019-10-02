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

-(void)setOverriddenDocumentPath:(NSURL*)url;
-(void)setOverriddenDatabasePath:(NSURL*)url;

-(void)unzipDownloadedPackage:(NSURL*)downloadedPackagePath packageName:(NSString*)packageName;

-(NSArray<Package*>*)collectPackages;
-(void)savePackageState:(Package*)pack;
-(NSDictionary<NSString*, NSArray<SavedCrossword*>*>*)collectSavedCrosswords;
-(NSArray<SavedCrossword*>*)collectMinimalStatCountCWSet:(NSString*)packageKey;
-(uint32_t)getMaxStatCountOfCWSet:(NSString*)packageKey;
-(GeneratorInfo*)collectGeneratorInfo:(NSArray<Deck*>*)decks;
-(void)reloadUsedWords:(NSURL*)packagePath info:(GeneratorInfo*)info;

-(NSString*)trimQuestionField:(NSString*)questionField;
-(NSString*)trimSolutionField:(NSString*)solutionField splitArr:(NSArray<NSString*>*)splitArr solutionFixes:(NSDictionary<NSString*, NSString*>*)solutionFixes;
-(NSString*)generateWithInfo:(GeneratorInfo*)info progressCallback:(void(^)(float, BOOL*))progressCallback;

@end
