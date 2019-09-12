#include "JavaString.h"
#include "JavaArrays.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI helper for JavaString class
////////////////////////////////////////////////////////////////////////////////////////////////////
namespace jni_string {
//Java class signature
	JNI::jClassID jStringClass {"java/lang/String"};

//Java method and field signatures
	JNI::jCallableID jInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jInitWithBytesMethod {JNI::JMETHOD, "<init>", "([B)V"};
	JNI::jCallableID jInitWithEncodingMethod {JNI::JMETHOD, "<init>", "([BLjava/lang/String;)V"};
	JNI::jCallableID jGetBytesMethod {JNI::JMETHOD, "getBytes", "()[B"};
	JNI::jCallableID jGetBytesWithEncodingMethod {JNI::JMETHOD, "getBytes", "(Ljava/lang/String;)[B"};
	JNI::jCallableID jValueOfObjectMethod {JNI::JSTATICMETHOD, "valueOf", "(Ljava/lang/Object;)Ljava/lang/String;"};
	JNI::jCallableID jToLowerCaseMethod {JNI::JMETHOD, "toLowerCase", "()Ljava/lang/String;"};
	JNI::jCallableID jLengthMethod {JNI::JMETHOD, "length", "()I"};

//Register jni calls
	JNI::CallRegister<jStringClass, jInitMethod, jInitWithBytesMethod, jInitWithEncodingMethod, jGetBytesMethod,
		jGetBytesWithEncodingMethod, jValueOfObjectMethod, jToLowerCaseMethod, jLengthMethod> JNI_JavaString;
}

using namespace jni_string;

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaString class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaString::JavaString () : JavaObject () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jStringClass), JNI::JavaMethod (jInitMethod)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

JavaString::JavaString (jstring obj) : JavaObject (obj) {
	if (mObject == nullptr) { //The given obj is nullptr
		InitWithEncoding (nullptr, 0, "UTF-8");
	}
}

JavaString::JavaString (jobject obj) : JavaObject (obj) {
	if (mObject == nullptr) { //The given obj is nullptr
		InitWithEncoding (nullptr, 0, "UTF-8");
	}
}

std::string JavaString::getString () const {
	if (mObject == nullptr) {
		return std::string ();
	}

	JavaByteArray jarray = JNI::CallObjectMethod<JavaByteArray> (mObject, JNI::JavaMethod (jGetBytesMethod));
	return jarray.getString ();
}

std::string JavaString::getStringWithEncoding (const char* encoding) const {
	if (mObject == nullptr) {
		return std::string ();
	}

	// Worth considering this to use for most common case. Working, but needs review.
//	if (strcasecmp(encoding, "UTF-8") == 0) {
//		const char *sz = env->GetStringUTFChars ((jstring) mObject, 0);
//		std::string res (sz);
//		env->ReleaseStringUTFChars ((jstring) mObject, sz);
//		return res;
//	}

	if (encoding == nullptr) {
		return getString ();
	}

	JavaByteArray jarray = JNI::CallObjectMethod<JavaByteArray> (mObject, JNI::JavaMethod (jGetBytesWithEncodingMethod), JavaString (encoding).get ());
	if (JNI::ExceptionCatch ()) { //UnsupportedEncodingException (e.g. wrong UTF-8 content)
		return std::string ();
	}

	return jarray.getString ();
}

std::vector<uint8_t> JavaString::getBytes () const {
	if (mObject == nullptr) {
		return std::vector<uint8_t> ();
	}

	JavaByteArray jarray = JNI::CallObjectMethod<JavaByteArray> (mObject, JNI::JavaMethod (jGetBytesMethod));
	return jarray.getBytes ();
}

std::vector<uint8_t> JavaString::getBytesWithEncoding (const char* encoding) const {
	if (mObject == nullptr) {
		return std::vector<uint8_t> ();
	}

	JavaByteArray jarray = JNI::CallObjectMethod<JavaByteArray> (mObject, JNI::JavaMethod (jGetBytesWithEncodingMethod), JavaString (encoding).get ());
	if (JNI::ExceptionCatch ()) { //UnsupportedEncodingException (e.g. wrong UTF-8 content)
		return std::vector<uint8_t> ();
	}

	return jarray.getBytes ();
}

std::string JavaString::valueOf (JavaObject javaObject) {
	return JNI::CallStaticObjectMethod<JavaString> (JNI::JavaClass (jStringClass), JNI::JavaMethod (jValueOfObjectMethod), javaObject.get ()).getString ();
}

JavaString JavaString::toLowerCase () const {
	return JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jToLowerCaseMethod));
}

int JavaString::length () const {
	return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jLengthMethod));
}

void JavaString::InitWithEncoding (const char* bytes, int length, const char* encoding) {
	JNIEnv* env = JNI::GetEnv ();

	if (bytes == nullptr || length <= 0) { //If the source string is and empty C string!
		JNI::AutoLocalRef<jobject> jobj (env->NewObject (JNI::JavaClass (jStringClass), JNI::JavaMethod (jInitMethod)));
		mObject = JNI::GlobalReferenceObject (jobj.get ());
	} else { //The source is a valid C string!
		if (encoding == nullptr) {
			JNI::AutoLocalRef<jobject> jobj (env->NewObject (JNI::JavaClass (jStringClass), JNI::JavaMethod (jInitWithBytesMethod), JavaByteArray (bytes, length).get ()));
			mObject = JNI::GlobalReferenceObject (jobj.get ());
		} else {
			JNI::AutoLocalRef<jstring> jencoding (env->NewStringUTF (encoding));
			JNI::AutoLocalRef<jobject> jobj (env->NewObject (JNI::JavaClass (jStringClass), JNI::JavaMethod (jInitWithEncodingMethod), JavaByteArray (bytes, length).get (), jencoding.get ()));
			mObject = JNI::GlobalReferenceObject (jobj.get ());
		}
	}

}