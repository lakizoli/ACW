//
//  NetPackConfig.mm
//  acwios
//
//  Created by Laki Zoltán on 2019. 07. 25..
//  Copyright © 2019. ZApp. All rights reserved.
//

#import "NetPackConfig.h"

@implementation NetPackConfigItem

@end

@implementation NetPackConfig {
	NSArray *_json;
}

-(id)initWithURL:(NSURL*)url {
	self = [super init];
	if (self) {
		NSError* error = nil;
		_json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:url] options:0 error:&error];
		
		if (error != nil) {
			NSLog (@"NetPackConfig initWithURL error: %@", error);
		}
	}
	
	return self;
}

-(NSUInteger)countOfLanguages {
	return [_json count];
}

-(void)enumerateLanguagesWihtBlock:(void(^)(NetPackConfigItem*))block {
	if (block == nil) {
		return;
	}
	
	for (NSUInteger i = 0, iEnd = [_json count]; i < iEnd; ++i) {
		NSDictionary *item = [_json objectAtIndex:i];
		if (item) {
			NetPackConfigItem *configItem = [[NetPackConfigItem alloc] init];
			configItem.label = [item objectForKey:@"name"];
			configItem.fileID = [item objectForKey:@"fileID"];
			configItem.size = [[item objectForKey:@"size"] unsignedIntegerValue];
			
			block (configItem);
		}
	}
}

@end
