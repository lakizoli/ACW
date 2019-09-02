//
//  JavaContext.hpp
//  Connector
//
//  Created by Szauka Attila on 2018. 11. 20..
//  Copyright © 2018. Graphisoft. All rights reserved.
//

#ifndef BIMX_JAVACONTEXT_HPP
#define BIMX_JAVACONTEXT_HPP

#include "JavaObject.h"
#include "jniapi.h"
#include "JavaFile.hpp"
#include "JavaTypes.h"

class JavaContext : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaContext);

public:
	JavaObject getSystemService (const JavaString& serviceName) const;

	JavaFile getFilesDir () const;
	JavaFile getDatabasePath (const JavaString& name) const;
	JavaFile getExternalFilesDir () const;
	JavaFile getCacheDir () const;

	static JavaString CONNECTIVITY_SERVICE ();

	JavaObject getAssets () const;
};

#endif //BIMX_JAVACONTEXT_HPP