//
//  NetPackConfig.h
//  acwios
//
//  Created by Laki Zoltán on 2019. 07. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetPackConfigItem : NSObject

@property (nonatomic) NSString *label;
@property (nonatomic) NSString *fileID;
@property (nonatomic) NSUInteger size;

@end

@interface NetPackConfig : NSObject

-(id)initWithURL:(NSURL*)url;

-(NSUInteger)countOfLanguages;
-(void)enumerateLanguagesWihtBlock:(void(^)(NetPackConfigItem*))block;

@end

NS_ASSUME_NONNULL_END
