//
//  BasicDatabase.hpp
//  adb
//
//  Created by Laki Zoltán on 2018. 07. 29..
//  Copyright © 2018. ZApp. All rights reserved.
//

#ifndef BasicDatabase_hpp
#define BasicDatabase_hpp

class BasicDatabase {
	BasicDatabase ();
	
public:
	static std::shared_ptr<BasicDatabase> Create (const std::string& path);
};

#endif /* BasicDatabase_hpp */
