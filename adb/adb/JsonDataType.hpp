//
//  JsonDataType.hpp
//  Common
//
//  Created by Laki, Zoltan on 2017. 09. 20..
//  Copyright © 2017. ZApp. All rights reserved.
//

#ifndef JsonDataType_hpp
#define JsonDataType_hpp

enum class JsonDataType {
	Unknown,
	
	String,
	Bool,
	Int32,
	Int64,
	UInt32,
	UInt64,
	Double,
	Object,
	Array
};

#endif /* JsonDataType_hpp */
