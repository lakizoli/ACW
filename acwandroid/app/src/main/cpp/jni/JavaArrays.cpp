#include "JavaArrays.h"
#include "JavaString.h"
#include <cassert>
#include <cstdio>

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI helper for Java Arrays
////////////////////////////////////////////////////////////////////////////////////////////////////
namespace jni_arrays {
//Java class signature
	JNI::jClassID jByteArrayClass {"[B"};
	JNI::jClassID jFloatArrayClass {"[F"};
	JNI::jClassID jIntArrayClass {"[I"};
	JNI::jClassID jLongArrayClass {"[J"};
	JNI::jClassID jStringArrayClass {"[Ljava/lang/String;"};

//Java method and field signatures

//Register jni calls
	JNI::CallRegister<jByteArrayClass> JNI_JavaByteArray;
	JNI::CallRegister<jFloatArrayClass> JNI_JavaFloatArray;
	JNI::CallRegister<jIntArrayClass> JNI_JavaIntArray;
	JNI::CallRegister<jLongArrayClass> JNI_JavaLongArray;
	JNI::CallRegister<jStringArrayClass> JNI_JavaStringArray;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaByteArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaByteArray::JavaByteArray (jobject object) : JavaObject (object) {
	if (mObject == nullptr) {
		InitWithBytes (nullptr, 0);
	}

	CHECKMSG (mObject != nullptr, "JavaByteArray::JavaByteArray (jobject object) - object is nullptr!");
}

std::vector<uint8_t> JavaByteArray::getBytes () const {
	int len = length ();
	if (len <= 0) {
		return std::vector<uint8_t> ();
	}

	JNIEnv* env = JNI::GetEnv ();

	jbyte* bytes = nullptr;
	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jByteArrayClass))) { //byte[]
		bytes = env->GetByteArrayElements ((jbyteArray) mObject, nullptr);
	} else { //NIO buffer
		bytes = reinterpret_cast<jbyte*> (env->GetDirectBufferAddress (mObject));
	}

	CHECKMSG (bytes != nullptr, "JavaByteArray ()::getBytes () - bytes cannot be nullptr!");

	std::vector<uint8_t> res (bytes, bytes + len);
	env->ReleaseByteArrayElements ((jbyteArray) mObject, bytes, JNI_ABORT);

	return res;
}

std::string JavaByteArray::getString () const {
	int len = length ();
	if (len <= 0) {
		return std::string ();
	}

	JNIEnv* env = JNI::GetEnv ();

	jbyte* bytes = nullptr;
	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jByteArrayClass))) { //byte[]
		bytes = env->GetByteArrayElements ((jbyteArray) mObject, nullptr);
	} else { //NIO buffer
		bytes = reinterpret_cast<jbyte*> (env->GetDirectBufferAddress (mObject));
	}

	CHECKMSG (bytes != nullptr, "JavaByteArray ()::getBytes () - bytes cannot be nullptr!");

	std::string res ((const char*) bytes, (size_t) len);
	env->ReleaseByteArrayElements ((jbyteArray) mObject, bytes, JNI_ABORT);

	return res;
}

int JavaByteArray::length () const {
	if (mObject == nullptr) {
		return 0;
	}

	JNIEnv* env = JNI::GetEnv ();

	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jByteArrayClass))) { //byte[]
		return env->GetArrayLength ((jbyteArray) mObject);
	}

	//NIO buffer
	return env->GetDirectBufferCapacity (mObject);
}

void JavaByteArray::InitWithLength (int length) {
	CHECKMSG (length >= 0, "JavaByteArray::InitWithLength (int length) - Cannot create byte[] with negative length!");

	JNIEnv* env = JNI::GetEnv ();

	JNI::AutoLocalRef<jobject> jobj = env->NewByteArray (length);
	CHECKMSG (!env->ExceptionCheck (), "JavaByteArray::InitWithLength (int length) - Cannot allocate byte[]! Java exception occurred!");

	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

void JavaByteArray::InitWithBytes (const char* bytes, int length) {
	CHECKMSG (bytes != nullptr, "JavaByteArray::JavaByteArray (const char* bytes, int length) - bytes is nullptr!");

	InitWithLength (length);

	if (bytes != nullptr && length > 0) {
		JNIEnv* env = JNI::GetEnv ();
		env->SetByteArrayRegion ((jbyteArray) mObject, 0, length, (const jbyte*) bytes);
		CHECKMSG (!env->ExceptionCheck (), "JavaByteArray::JavaByteArray (const char* bytes, int length) - Cannot set content! Java exception occurred!");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaFloatArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaFloatArray::JavaFloatArray (jobject object) : JavaObject (object) {
	if (mObject == nullptr) {
		InitWithFloats (nullptr, 0);
	}

	CHECKMSG (mObject != nullptr, "JavaFloatArray::JavaFloatArray (jobject object) - object is nullptr!");
}

//JavaFloatArray::JavaFloatArray (const BXRect<float>& rect) : JavaObject () {
//	float vec[4] = {rect.left, rect.top, rect.right, rect.bottom};
//	InitWithFloats (vec, 4);
//}

std::vector<float> JavaFloatArray::getVector () const {
	int len = length ();
	if (len <= 0) {
		return std::vector<float> ();
	}

	JNIEnv* env = JNI::GetEnv ();

	jfloat* floats = nullptr;
	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jFloatArrayClass))) { //float[]
		floats = env->GetFloatArrayElements ((jfloatArray) mObject, nullptr);
	} else { //NIO buffer
		floats = reinterpret_cast<jfloat*> (env->GetDirectBufferAddress (mObject));
	}

	CHECKMSG (floats != nullptr, "JavaFloatArray ()::getVector () - floats cannot be nullptr!");

	std::vector<float> res (floats, floats + len);
	env->ReleaseFloatArrayElements ((jfloatArray) mObject, floats, JNI_ABORT);

	return res;
}

//BXRect<float> JavaFloatArray::getBXRect () const {
//	vector<float>&& vec = getVector ();
//	if (vec.size () >= 4)
//		return BXRect<float> (vec[0], vec[1], vec[2], vec[3]);
//	return BXRect<float> ();
//}
//
//BXVector3 JavaFloatArray::getBXVector3 () const {
//	vector<float>&& vec = getVector ();
//	if (vec.size () >= 3)
//		return BXVector3 (vec[0], vec[1], vec[2]);
//	return BXVector3 ();
//}
//
//BXVector4 JavaFloatArray::getBXVector4 () const {
//	vector<float>&& vec = getVector ();
//	if (vec.size () >= 4)
//		return BXVector4 (vec[0], vec[1], vec[2], vec[3]);
//	return BXVector4 ();
//}
//
//glm::vec2 JavaFloatArray::getVector2 () const {
//	vector<float>&& vec = getVector ();
//	if (vec.size () >= 2)
//		return glm::vec2 (vec[0], vec[1]);
//	return glm::vec2 ();
//}
//
//glm::vec3 JavaFloatArray::getVector3 () const {
//	vector<float>&& vec = getVector ();
//	if (vec.size () >= 3)
//		return glm::vec3 (vec[0], vec[1], vec[2]);
//	return glm::vec3 ();
//}
//
//glm::vec4 JavaFloatArray::getVector4 () const {
//	vector<float>&& vec = getVector ();
//	if (vec.size () >= 4)
//		return glm::vec4 (vec[0], vec[1], vec[2], vec[3]);
//	return glm::vec4 ();
//}
//
//glm::mat4x4 JavaFloatArray::getMatrix4x4 () const {
//	vector<float>&& vec = getVector ();
//	if (vec.size () >= 16) {
//		return glm::mat4x4 (vec[0], vec[1], vec[2], vec[3],
//							vec[4], vec[5], vec[6], vec[7],
//							vec[8], vec[9], vec[10], vec[11],
//							vec[12], vec[13], vec[14], vec[15]);
//	}
//	return glm::mat4x4 ();
//}

int JavaFloatArray::length () const {
	if (mObject == nullptr) {
		return 0;
	}

	JNIEnv* env = JNI::GetEnv ();

	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jFloatArrayClass))) { //float[]
		return env->GetArrayLength ((jfloatArray) mObject);
	}

	//NIO buffer
	return env->GetDirectBufferCapacity (mObject);
}

void JavaFloatArray::InitWithFloats (const float* floats, int length) {
	CHECKMSG (length >= 0, "JavaFloatArray::JavaFloatArray (const float* floats, int length) - Cannot create float[] with negative length!");
	CHECKMSG (length == 0 || (length > 0 && floats != nullptr), "JavaFloatArray::JavaFloatArray (const float* floats, int length) - floats is nullptr!");

	JNIEnv* env = JNI::GetEnv ();

	JNI::AutoLocalRef<jobject> jobj = env->NewFloatArray (length);
	CHECKMSG (!env->ExceptionCheck (), "JavaFloatArray::JavaFloatArray (const float* floats, int length) - Cannot allocate float[]! Java exception occurred!");

	mObject = JNI::GlobalReferenceObject (jobj.get ());

	if (floats != nullptr && length > 0) {
		env->SetFloatArrayRegion ((jfloatArray) mObject, 0, length, (const jfloat*) floats);
		CHECKMSG (!env->ExceptionCheck (), "JavaFloatArray::JavaFloatArray (const float* floats, int length) - Cannot set content! Java exception occurred!");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaIntArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaIntArray::JavaIntArray (jobject object) : JavaObject (object) {
	if (mObject == nullptr) {
		InitWithInts (nullptr, 0);
	}

	CHECKMSG (mObject != nullptr, "JavaIntArray::JavaIntArray (jobject object) - object is nullptr!");
}

std::vector<int> JavaIntArray::getInts () const {
	int len = length ();
	if (len <= 0) {
		return std::vector<int> ();
	}

	JNIEnv* env = JNI::GetEnv ();

	jint* ints = nullptr;
	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jIntArrayClass))) { //int[]
		ints = env->GetIntArrayElements ((jintArray) mObject, nullptr);
	} else { //NIO buffer
		ints = reinterpret_cast<jint*> (env->GetDirectBufferAddress (mObject));
	}

	CHECKMSG (ints != nullptr, "JavaIntArray ()::getInts () - ints cannot be nullptr!");

	std::vector<int> res (ints, ints + len);
	env->ReleaseIntArrayElements ((jintArray) mObject, ints, JNI_ABORT);

	return res;
}

int JavaIntArray::length () const {
	if (mObject == nullptr) {
		return 0;
	}

	JNIEnv* env = JNI::GetEnv ();

	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jIntArrayClass))) { //int[]
		return env->GetArrayLength ((jintArray) mObject);
	}

	//NIO buffer
	return env->GetDirectBufferCapacity (mObject);
}

void JavaIntArray::InitWithInts (const int* ints, int length) {
	CHECKMSG (length >= 0, "JavaIntArray::JavaIntArray (const int* ints, int length) - Cannot create int[] with negative length!");
	CHECKMSG (length == 0 || (length > 0 && ints != nullptr), "JavaIntArray::JavaIntArray (const int* ints, int length) - ints is nullptr!");

	JNIEnv* env = JNI::GetEnv ();

	JNI::AutoLocalRef<jobject> jobj = env->NewIntArray (length);
	CHECKMSG (!env->ExceptionCheck (), "JavaIntArray::JavaIntArray (const int* ints, int length) - Cannot allocate int[]! Java exception occurred!");

	mObject = JNI::GlobalReferenceObject (jobj.get ());

	if (ints != nullptr && length > 0) {
		env->SetIntArrayRegion ((jintArray) mObject, 0, length, (const jint*) ints);
		CHECKMSG (!env->ExceptionCheck (), "JavaIntArray::JavaIntArray (const int* ints, int length) - Cannot set content! Java exception occurred!");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaLongArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaLongArray::JavaLongArray (jobject object) : JavaObject (object) {
	if (mObject == nullptr) {
		InitWithLongs (nullptr, 0);
	}

	CHECKMSG (mObject != nullptr, "JavaLongArray::JavaLongArray (jobject object) - object is nullptr!");
}

std::vector<int64_t> JavaLongArray::getLongs () const {
	int len = length ();
	if (len <= 0) {
		return std::vector<int64_t> ();
	}

	JNIEnv* env = JNI::GetEnv ();

	jlong* longs = nullptr;
	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jLongArrayClass))) { //long[]
		longs = env->GetLongArrayElements ((jlongArray) mObject, nullptr);
	} else { //NIO buffer
		longs = reinterpret_cast<jlong*> (env->GetDirectBufferAddress (mObject));
	}

	CHECKMSG (longs != nullptr, "JavaLongArray ()::getLongs () - longs cannot be nullptr!");

	std::vector<int64_t> res (longs, longs + len);
	env->ReleaseLongArrayElements ((jlongArray) mObject, longs, JNI_ABORT);

	return res;
}

int JavaLongArray::length () const {
	if (mObject == nullptr) {
		return 0;
	}

	JNIEnv* env = JNI::GetEnv ();

	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jLongArrayClass))) { //long[]
		return env->GetArrayLength ((jlongArray) mObject);
	}

	//NIO buffer
	return env->GetDirectBufferCapacity (mObject);
}

void JavaLongArray::InitWithLongs (const int64_t* longs, int length) {
	CHECKMSG (length >= 0, "JavaLongArray::JavaLongArray (const int64_t* longs, int length) - Cannot create long[] with negative length!");
	CHECKMSG (length == 0 || (length > 0 && longs != nullptr), "JavaLongArray::JavaLongArray (const int64_t* longs, int length) - longs is nullptr!");

	JNIEnv* env = JNI::GetEnv ();

	JNI::AutoLocalRef<jobject> jobj = env->NewLongArray (length);
	CHECKMSG (!env->ExceptionCheck (), "JavaLongArray::JavaLongArray (const int64_t* longs, int length) - Cannot allocate long[]! Java exception occurred!");

	mObject = JNI::GlobalReferenceObject (jobj.get ());

	if (longs != nullptr && length > 0) {
		env->SetLongArrayRegion ((jlongArray) mObject, 0, length, (jlong*) longs);
		CHECKMSG (!env->ExceptionCheck (), "JavaLongArray::JavaLongArray (const int64_t* longs, int length) - Cannot set content! Java exception occurred!");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaStringArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaStringArray::JavaStringArray (jobject object) : JavaObject (object) {
	if (mObject == nullptr) {
		InitWithStrings ({});
	}

	CHECKMSG (mObject != nullptr, "JavaStringArray::JavaStringArray (jobject object) - object is nullptr!");
};

std::vector<std::string> JavaStringArray::getStrings () const {
	std::vector<std::string> res;

	int len = length ();
	if (len <= 0) {
		return res;
	}

	JNIEnv* env = JNI::GetEnv ();
	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jStringArrayClass))) { // String[]
		for (int i = 0; i < len; i++) {
			JNI::AutoLocalRef<jobject> jItem (env->GetObjectArrayElement ((jobjectArray) mObject, i));
			res.push_back (JavaString (jItem).getString ());
		}
	}

	return res;
};

int JavaStringArray::length () const {
	if (mObject == nullptr) {
		return 0;
	}

	JNIEnv* env = JNI::GetEnv ();
	if (env->IsInstanceOf (mObject, JNI::JavaClass (jni_arrays::jStringArrayClass))) { //Object[]
		return env->GetArrayLength ((jobjectArray) mObject);
	}

	return 0;
}

void JavaStringArray::InitWithStrings (const std::vector<std::string>& strings) {
	JNIEnv* env = JNI::GetEnv ();

	JNI::AutoLocalRef<jobject> jobj = env->NewObjectArray ((jsize) strings.size (), JNI::JavaClass (jni_string::jStringClass), JavaString ().get ());
	CHECKMSG (!env->ExceptionCheck (), "JavaStringArray::JavaStringArray (const std::vector<std::string>& strings) - Cannot allocate String[]! Java exception occurred!");

	mObject = JNI::GlobalReferenceObject (jobj.get ());

	if (!strings.empty ()) {
		for (size_t i = 0, iEnd = strings.size (); i < iEnd; ++i) {
			env->SetObjectArrayElement ((jobjectArray) jobj.get (), (jsize) i, JavaString (strings[i]).get ());
			CHECKMSG (!env->ExceptionCheck (), "JavaStringArray::JavaStringArray (const std::vector<std::string>& strings) - Cannot set content! Java exception occurred!");
		}
	}
};
