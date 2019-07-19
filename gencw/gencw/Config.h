//
//  Config.h
//  gencw
//
//  Created by Laki Zoltán on 2019. 07. 19..
//  Copyright © 2019. Laki Zoltán. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PackageConfig : NSObject

-(NSString*)getBaseName;
-(NSUInteger)getWidth;
-(NSUInteger)getHeight;
-(NSUInteger)getQuestionIndex;
-(NSUInteger)getSolutionIndex;

@end

@interface Config : NSObject

+(Config*)createWithURL:(NSURL*)url;

-(PackageConfig*)getPackageConfig:(NSString*)name;
-(NSString*)getOutputPath;

@end

NS_ASSUME_NONNULL_END
