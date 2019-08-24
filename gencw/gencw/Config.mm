//
//  Config.mm
//  gencw
//
//  Created by Laki Zoltán on 2019. 07. 19..
//  Copyright © 2019. Laki Zoltán. All rights reserved.
//

#import "Config.h"

@implementation PackageConfig {
	NSDictionary *_json;
}

-(id)initWithJson:(NSDictionary*)json {
	self = [super init];
	if (self) {
		_json = json;
	}
	return self;
}

-(NSString*)getBaseName {
	return [_json objectForKey:@"basename"];
}

-(NSUInteger)getWidth {
	return [[_json objectForKey:@"width"] unsignedIntegerValue];
}

-(NSUInteger)getHeight {
	return [[_json objectForKey:@"height"] unsignedIntegerValue];
}

-(NSUInteger)getQuestionIndex {
	return [[_json objectForKey:@"question"] unsignedIntegerValue];
}

-(NSUInteger)getSolutionIndex {
	return [[_json objectForKey:@"solution"] unsignedIntegerValue];
}

-(BOOL)hasSplitArray {
	return [[self getSplitArray] count] > 0;
}

-(NSArray<NSString*>*) getSplitArray {
	NSArray<NSString*> *splitArr = [_json objectForKey:@"splitArray"];
	if (splitArr) {
		return splitArr;
	}
	return [NSArray new];
}

-(NSDictionary<NSString*,NSString*>*)getSolutionFixes {
	NSDictionary<NSString*,NSString*>* res = [_json objectForKey:@"solutionFixes"];
	if (res) {
		return res;
	}
	return [NSDictionary new];
}

@end

@implementation Config {
	NSDictionary *_json;
}

+(Config*)createWithURL:(NSURL*)url {
	Config *cfg = [[Config alloc] init];
	
	NSError* error = nil;
	cfg->_json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:url]
												 options:0
												   error:&error];
	if (error != nil) {
		return nil;
	}
	
	return cfg;
}

-(PackageConfig*)getPackageConfig:(NSString*)name {
	return [[PackageConfig alloc] initWithJson:[_json objectForKey:name]];
}

-(NSString*)getOutputPath {
	return [_json objectForKey:@"outputPath"];
}

@end
