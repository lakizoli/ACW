#include <inttypes.h>
#include "JavaTypes.h"
#include "JavaString.h"
#include "jniapi.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI helper for Java Types
////////////////////////////////////////////////////////////////////////////////////////////////////
namespace jni_types {
//Java class signature
	JNI::jClassID jBooleanClass {"java/lang/Boolean"};
	JNI::jClassID jIntegerClass {"java/lang/Integer"};
	JNI::jClassID jLongClass {"java/lang/Long"};
	JNI::jClassID jFloatClass {"java/lang/Float"};
	JNI::jClassID jDoubleClass {"java/lang/Double"};
	JNI::jClassID jNumberClass {"java/lang/Number"};
	JNI::jClassID jBigIntegerClass {"java/math/BigInteger"};
	JNI::jClassID jUUIDClass {"java/util/UUID"};

//Java method and field signatures
	JNI::jCallableID jBooleanInitMethod {JNI::JMETHOD, "<init>", "(Z)V"};
	JNI::jCallableID jBooleanValueMethod {JNI::JMETHOD, "booleanValue", "()Z"};

	JNI::jCallableID jIntegerInitMethod {JNI::JMETHOD, "<init>", "(I)V"};
	JNI::jCallableID jIntegerValueMethod {JNI::JMETHOD, "intValue", "()I"};

	JNI::jCallableID jLongInitMethod {JNI::JMETHOD, "<init>", "(J)V"};
	JNI::jCallableID jLongValueMethod {JNI::JMETHOD, "longValue", "()J"};

	JNI::jCallableID jFloatInitMethod {JNI::JMETHOD, "<init>", "(F)V"};
	JNI::jCallableID jFloatValueMethod {JNI::JMETHOD, "floatValue", "()F"};

	JNI::jCallableID jDoubleInitMethod {JNI::JMETHOD, "<init>", "(D)V"};
	JNI::jCallableID jDoubleValueMethod {JNI::JMETHOD, "doubleValue", "()D"};

	JNI::jCallableID jNumberDoubleValueMethod {JNI::JMETHOD, "doubleValue", "()D"};
	JNI::jCallableID jNumberIntValueMethod {JNI::JMETHOD, "intValue", "()I"};

	JNI::jCallableID jBIInitMethod {JNI::JMETHOD, "<init>", "(Ljava/lang/String;)V"};
	JNI::jCallableID jBIToStringMethod {JNI::JMETHOD, "toString", "()Ljava/lang/String;"};

	JNI::jCallableID jUUIDInitMethod {JNI::JMETHOD, "<init>", "(JJ)V"};
	JNI::jCallableID jUUIDRandomMethod {JNI::JSTATICMETHOD, "randomUUID", "()Ljava/util/UUID;"};
	JNI::jCallableID jGetLeastSignificantBitsMethod {JNI::JMETHOD, "getLeastSignificantBits", "()J"};
	JNI::jCallableID jGetMostSignificantBitsMethod {JNI::JMETHOD, "getMostSignificantBits", "()J"};
	JNI::jCallableID jUUIDToStringMethod {JNI::JMETHOD, "toString", "()Ljava/lang/String;"};

//Register jni calls
	JNI::CallRegister<jBooleanClass, jBooleanInitMethod, jBooleanValueMethod> JNI_JavaBoolean;
	JNI::CallRegister<jni_types::jIntegerClass, jIntegerInitMethod, jIntegerValueMethod> JNI_JavaInteger;
	JNI::CallRegister<jLongClass, jLongInitMethod, jLongValueMethod> JNI_JavaLong;
	JNI::CallRegister<jFloatClass, jFloatInitMethod, jFloatValueMethod> JNI_JavaFloat;
	JNI::CallRegister<jDoubleClass, jDoubleInitMethod, jDoubleValueMethod> JNI_JavaDouble;
	JNI::CallRegister<jNumberClass, jNumberDoubleValueMethod, jNumberIntValueMethod> JNI_JavaNumber;
	JNI::CallRegister<jBigIntegerClass, jBIInitMethod, jBIToStringMethod> JNI_JavaBigInteger;
	JNI::CallRegister<jUUIDClass, jUUIDInitMethod, jUUIDRandomMethod, jGetLeastSignificantBitsMethod, jGetMostSignificantBitsMethod, jUUIDToStringMethod> JNI_JavaUUID;
}

using namespace jni_types;

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaBoolean class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaBoolean::JavaBoolean (bool value) : JavaObject () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jBooleanClass), JNI::JavaMethod (jBooleanInitMethod), (value ? JNI_TRUE : JNI_FALSE)));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

bool JavaBoolean::booleanValue () const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jBooleanValueMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaInteger class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaInteger::JavaInteger (int value) : JavaObject () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jIntegerClass), JNI::JavaMethod (jIntegerInitMethod), (jint) value));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

int JavaInteger::intValue () const {
	return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jIntegerValueMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaLong class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaLong::JavaLong (int64_t value) : JavaObject () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jLongClass), JNI::JavaMethod (jLongInitMethod), (jlong) value));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

int64_t JavaLong::longValue () const {
	return JNI::GetEnv ()->CallLongMethod (mObject, JNI::JavaMethod (jLongValueMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaFloat class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaFloat::JavaFloat (float value) : JavaObject () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jFloatClass), JNI::JavaMethod (jFloatInitMethod), (jfloat) value));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

float JavaFloat::floatValue () const {
	return JNI::GetEnv ()->CallFloatMethod (mObject, JNI::JavaMethod (jFloatValueMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaDouble class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaDouble::JavaDouble (double value) : JavaObject () {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jDoubleClass), JNI::JavaMethod (jDoubleInitMethod), (jdouble) value));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

double JavaDouble::doubleValue () const {
	return JNI::GetEnv ()->CallDoubleMethod (mObject, JNI::JavaMethod (jDoubleValueMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaNumber class
////////////////////////////////////////////////////////////////////////////////////////////////////
double JavaNumber::doubleValue () const {
	return JNI::GetEnv ()->CallDoubleMethod (mObject, JNI::JavaMethod (jNumberDoubleValueMethod));
}

double JavaNumber::intValue () const {
	return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jNumberIntValueMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaBigInteger class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaBigInteger::JavaBigInteger (uint64_t value) : JavaObject () {
	JavaString jstr (std::to_string (value));
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jBigIntegerClass), JNI::JavaMethod (jBIInitMethod), jstr.get ()));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

std::string JavaBigInteger::stringValue () const {
	return JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jBIToStringMethod)).getString ();
}

uint64_t JavaBigInteger::uint64Value () const {
	return std::stoull (stringValue ());
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaUUID class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaUUID::JavaUUID (int64_t low, int64_t high) {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jUUIDClass), JNI::JavaMethod (jUUIDInitMethod), (jlong) high, (jlong) low));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

JavaUUID JavaUUID::randomUUID () {
	return JNI::CallStaticObjectMethod<JavaUUID> (JNI::JavaClass (jUUIDClass), JNI::JavaMethod (jUUIDRandomMethod));
}

std::string JavaUUID::toString () const {
	return JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jUUIDToStringMethod)).getString ();
}

int64_t JavaUUID::getLeastSignificantBits () const {
	return JNI::GetEnv ()->CallLongMethod (mObject, JNI::JavaMethod (jGetLeastSignificantBitsMethod));
}

int64_t JavaUUID::getMostSignificantBits () const {
	return JNI::GetEnv ()->CallLongMethod (mObject, JNI::JavaMethod (jGetMostSignificantBitsMethod));
}
