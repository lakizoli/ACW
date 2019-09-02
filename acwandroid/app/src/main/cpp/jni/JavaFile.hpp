//
//  JavaFile.hpp
//  Connector
//
//  Created by Szauka Attila on 2018. 11. 20..
//  Copyright © 2018. Graphisoft. All rights reserved.
//

#ifndef BIMX_JAVAFILE_HPP
#define BIMX_JAVAFILE_HPP

#include "jniapi.h"
#include "JavaObject.h"
#include "JavaString.h"
#include "JavaArrays.h"
#include "JavaTypes.h"

class JavaFile : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaFile);

public:
	JavaFile (const JavaFile& file, const std::string& fileName);
	JavaFile (const std::string& fileName);

public:
	std::string getAbsolutePath () const;
	std::string getParent () const;

	bool exists () const;
	bool createNewFile () const;
	bool mkdir () const;
	bool mkdirs () const;

	bool setLastModified (int64_t time) const;
	int64_t lastModified () const;
	int64_t length () const;

	bool isDirectory () const;

	std::vector<std::string> list () const;
	std::string getName () const;

	bool deleteRecursively () const;
	bool moveTo (const std::string& destPath) const;
	bool copyRecursively (const std::string& destPath) const;
};


#endif //BIMX_JAVAFILE_HPP
