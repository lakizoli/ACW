//
// Created by Laki Zoltán on 2019-08-14.
//

#ifndef SRC_ANDROID_JAVAFUNCTION_HPP
#define SRC_ANDROID_JAVAFUNCTION_HPP

#include "JavaObject.h"

class JavaFunction : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaFunction);

public:
	JavaObject apply () const;
	JavaObject apply (JavaObject param) const;
};

#endif //SRC_ANDROID_JAVAFUNCTION_HPP
