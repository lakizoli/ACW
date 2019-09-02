//
// Created by Laki Zoltán on 2019-08-14.
//

#include "JavaFunction.hpp"
#include <jniapi.h>

namespace {
//Java class signature
	JNI::jClassID jFunctionClass {"java/util/function/Function"};

//Java method and field signatures
	JNI::jCallableID jApplyMethod {JNI::JMETHOD, "apply", "(Ljava/lang/Object;)Ljava/lang/Object;"};

//Register jni calls
	JNI::CallRegister<jFunctionClass, jApplyMethod> JNI_Function;
}

JavaObject JavaFunction::apply () const {
	return JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jApplyMethod), nullptr);
}

JavaObject JavaFunction::apply (JavaObject param) const {
	return JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jApplyMethod), param.get ());
}
