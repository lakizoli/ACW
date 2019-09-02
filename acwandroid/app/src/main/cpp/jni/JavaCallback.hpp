//
// Created by Laki Zoltán on 2019-08-14.
//

#ifndef SRC_ANDROID_JAVACALLBACK_HPP
#define SRC_ANDROID_JAVACALLBACK_HPP

#include "JavaObject.h"

template<typename Ret, typename ... Args>
class JavaCallback : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaCallback);

	std::function<Ret (Args...)> mCallback;

	void CreateJavaInstance () {
		JNI::AutoLocalRef<jclass> clazz = JNI::FindClass ("com/graphisoft/bimx/platformconnector/JavaCallback");
		jmethodID jInitMethod = JNI::GetMethod (clazz, "<init>", "()V");
		if (jInitMethod) {
			JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (clazz, jInitMethod));
			mObject = JNI::GlobalReferenceObject (jobj.get ());
		}
	}

public:
	JavaCallback (std::function<Ret (Args...)> callback) : mCallback (callback) {
		CreateJavaInstance ();
	}

	Ret apply (Args ...);
};

template<typename Ret>
class JavaCallback<Ret, void> : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaCallback);

	std::function<Ret ()> mCallback;

public:
	JavaCallback (std::function<Ret ()> callback);

	Ret apply ();
};

template<>
void JavaCallback<void, void>::apply () {
	mCallback ();
}

template<>
void JavaCallback<void, std::string>::apply (std::string arg) {
	mCallback (arg);
}

#endif //SRC_ANDROID_JAVACALLBACK_HPP
