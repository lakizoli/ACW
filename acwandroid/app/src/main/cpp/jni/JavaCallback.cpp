//
// Created by Laki Zoltán on 2019-08-14.
//

#include "JavaCallback.hpp"
#include "JavaString.h"

extern "C" JNIEXPORT jobject JNICALL Java_com_graphisoft_bimx_platformconnector_JavaCallback_callNative (JNIEnv* env, jobject instance, jobject arg) {
	JavaObject jArg (arg);

	//Take care: handling of parameterized return types not handled in templates. So only void return type is supported at this time!
	if (jArg.IsInstanceOf ("java/lang/Void")) {
		JavaCallback<void, void> jCallback (instance);
		jCallback.apply ();
		return nullptr;
	} else if (jArg.IsInstanceOf ("java/lang/String")) {
		JavaCallback<void, std::string> jCallback (instance);
		jCallback.apply (JavaString (arg).getString ());
		return nullptr;
	}

	//Unhandled callback type
	return nullptr;
}