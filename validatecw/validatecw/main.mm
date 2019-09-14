//
//  main.mm
//  validatecw
//
//  Created by Laki Zoltán on 2019. 09. 14..
//  Copyright © 2019. Laki Zoltán. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "FillTest.hpp"

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		std::string dir = "/Users/zoli/Library/Developer/CoreSimulator/Devices/E029C46A-9A36-4733-A7EB-7E5DBE4D6B92/data/Containers/Data/Application/248A7FF2-011C-47B6-98A3-E210451ADEB3/Documents/packages/Erwin_Tschirner_Angol_szkincs_-_hu-en/";
		std::string cwName = "ADF55463-D958-44CE-97F6-EBB7B6612581.cw";
		
		if (!FillTest::ValidateCrossword (dir, cwName)) {
			return 1;
		}
	}
	return 0;
}
