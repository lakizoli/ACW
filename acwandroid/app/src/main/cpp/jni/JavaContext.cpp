//
//  JavaContext.cpp
//  Connector
//
//  Created by Szauka Attila on 2018. 11. 20..
//  Copyright © 2018. Graphisoft. All rights reserved.
//

#include "JavaContext.hpp"
#include "JavaObject.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI helper for JavaContext class
////////////////////////////////////////////////////////////////////////////////////////////////////
namespace {
//Java class signature
	JNI::jClassID jContextClass {"android/content/Context"};

//Java method and field signatures
	JNI::jCallableID jGetSystemServiceMethod {JNI::JMETHOD, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"};
	JNI::jCallableID jGetFilesDirMethod {JNI::JMETHOD, "getFilesDir", "()Ljava/io/File;"};
	JNI::jCallableID jGetDatabasePathMethod {JNI::JMETHOD, "getDatabasePath", "(Ljava/lang/String;)Ljava/io/File;"};
	JNI::jCallableID jGetExternalFilesDirMethod {JNI::JMETHOD, "getExternalFilesDir", "(Ljava/lang/String;)Ljava/io/File;"};
	JNI::jCallableID jGetCacheDirMethod {JNI::JMETHOD, "getCacheDir", "()Ljava/io/File;"};
	JNI::jCallableID jCONNECTIVITY_SERVICE_Field {JNI::JSTATICFIELD, "CONNECTIVITY_SERVICE", "Ljava/lang/String;"};
	JNI::jCallableID jGetAssetsMethod {JNI::JMETHOD, "getAssets", "()Landroid/content/res/AssetManager;"};

//Register jni calls
	JNI::CallRegister<jContextClass, jGetSystemServiceMethod, jGetFilesDirMethod, jGetDatabasePathMethod, jGetExternalFilesDirMethod,
		jGetCacheDirMethod, jCONNECTIVITY_SERVICE_Field, jGetAssetsMethod> JNI_JavaContext;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaContext class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaObject JavaContext::getSystemService (const JavaString& serviceName) const {
	return JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jGetSystemServiceMethod), serviceName.get ());
}

JavaFile JavaContext::getFilesDir () const {
	return JNI::CallObjectMethod<JavaFile> (mObject, JNI::JavaMethod (jGetFilesDirMethod));
}

JavaFile JavaContext::getDatabasePath (const JavaString& name) const {
	return JNI::CallObjectMethod<JavaFile> (mObject, JNI::JavaMethod (jGetDatabasePathMethod), name.get ());
}

JavaFile JavaContext::getExternalFilesDir () const {
	return JNI::CallObjectMethod<JavaFile> (mObject, JNI::JavaMethod (jGetExternalFilesDirMethod), nullptr);
}

JavaFile JavaContext::getCacheDir () const {
	return JNI::CallObjectMethod<JavaFile> (mObject, JNI::JavaMethod (jGetCacheDirMethod));
}

JavaString JavaContext::CONNECTIVITY_SERVICE () {
	return JNI::GetStaticObjectField<JavaString> (JNI::JavaClass (jContextClass), JNI::JavaStaticField (jCONNECTIVITY_SERVICE_Field));
}

JavaObject JavaContext::getAssets () const {
	return JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jGetAssetsMethod));
}





