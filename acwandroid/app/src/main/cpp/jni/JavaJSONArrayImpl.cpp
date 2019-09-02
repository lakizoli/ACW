#include <jniapi.h>
#include <JavaString.h>
#include <JavaTypes.h>
#include <JavaArrays.h>
#include <sstream>
#include "JavaJSONArrayImpl.hpp"
#include "JavaJSONObjectImpl.hpp"

namespace
{
	JNI::jClassID jJSONArrayClass{"org/json/JSONArray"};

	JNI::jCallableID jInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jInitStringMethod {JNI::JMETHOD, "<init>", "(Ljava/lang/String;)V"};

	JNI::jCallableID jOptMethod {JNI::JMETHOD, "opt", "(I)Ljava/lang/Object;"};

	JNI::jCallableID jPutBooleanMethod {JNI::JMETHOD, "put", "(Z)Lorg/json/JSONArray;"};
	JNI::jCallableID jPutIntMethod {JNI::JMETHOD, "put", "(I)Lorg/json/JSONArray;"};
	JNI::jCallableID jPutLongMethod {JNI::JMETHOD, "put", "(J)Lorg/json/JSONArray;"};
	JNI::jCallableID jPutDoubleMethod {JNI::JMETHOD, "put", "(D)Lorg/json/JSONArray;"};
	JNI::jCallableID jPutObjectMethod {JNI::JMETHOD, "put", "(Ljava/lang/Object;)Lorg/json/JSONArray;"};

	JNI::jCallableID jLengthMethod {JNI::JMETHOD, "length", "()I"};

	JNI::jCallableID jOptStringMethod {JNI::JMETHOD, "optString", "(ILjava/lang/String;)Ljava/lang/String;"};
	JNI::jCallableID jOptBooleanMethod {JNI::JMETHOD, "optBoolean", "(IZ)Z"};
	JNI::jCallableID jOptIntMethod {JNI::JMETHOD, "optInt", "(II)I"};
	JNI::jCallableID jOptLongMethod {JNI::JMETHOD, "optLong", "(IJ)J"};
	JNI::jCallableID jOptDoubleMethod {JNI::JMETHOD, "optDouble", "(ID)D"};
	JNI::jCallableID jOptJSONObjectMethod {JNI::JMETHOD, "optJSONObject", "(I)Lorg/json/JSONObject;"};
	JNI::jCallableID jOptJSONArrayMethod {JNI::JMETHOD, "optJSONArray", "(I)Lorg/json/JSONArray;"};

	JNI::jCallableID jToStringMethod {JNI::JMETHOD, "toString", "()Ljava/lang/String;"};
	JNI::jCallableID jToStringWithIndentMethod {JNI::JMETHOD, "toString", "(I)Ljava/lang/String;"};

	JNI::CallRegister<jJSONArrayClass, jInitMethod, jInitStringMethod, jOptMethod, jPutBooleanMethod,
			jPutIntMethod, jPutLongMethod, jPutDoubleMethod, jPutObjectMethod, jLengthMethod, jOptStringMethod,
			jOptBooleanMethod, jOptIntMethod, jOptLongMethod, jOptDoubleMethod, jOptJSONObjectMethod,
			jOptJSONArrayMethod, jToStringMethod, jToStringWithIndentMethod> JNI_JSONArray;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// JsonArray
////////////////////////////////////////////////////////////////////////////////////////////////////

std::shared_ptr<JsonArray> JsonArray::Create () {
	JNIEnv *env = JNI::GetEnv ();
	JNI::AutoLocalRef<jobject> jobj (env->NewObject (JNI::JavaClass (jJSONArrayClass), JNI::JavaMethod (jInitMethod)));
	return std::shared_ptr<JsonArrayImpl> (new JsonArrayImpl (jobj));
}

std::shared_ptr<JsonArray> JsonArray::Parse (const std::vector<uint8_t> &json) {
	return JsonArray::Parse (std::string (json.begin (), json.end ()));
}

std::shared_ptr<JsonArray> JsonArray::Parse (const std::string &json) {
	if (json.size () <= 0) {
		return nullptr;
	}

	//Parse JSON
	JNIEnv *env = JNI::GetEnv ();
	JNI::AutoLocalRef<jobject> jobj (env->NewObject (JNI::JavaClass (jJSONArrayClass), JNI::JavaMethod (jInitStringMethod), JavaString (json).get ()));

	if (JNI::ExceptionCatch()) {
		return nullptr;
	}

	return std::shared_ptr<JsonArrayImpl> (new JsonArrayImpl (jobj));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// JsonArrayImpl
////////////////////////////////////////////////////////////////////////////////////////////////////

JsonArrayImpl::JsonArrayImpl (jobject internalObject) {

	mObject = JNI::GlobalReferenceObject (internalObject);
}

bool JsonArrayImpl::HasNumberAtIndex (int32_t idx) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), (jint) idx);
	return obj.IsInstanceOf ("java/lang/Number");
}

void JsonArrayImpl::Add (const std::string &value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutObjectMethod), JavaString (value).get ());
	JNI::ClearExceptions ();
}

void JsonArrayImpl::Add (bool value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutBooleanMethod), JNI::ToJboolean (value));
	JNI::ClearExceptions ();
}

void JsonArrayImpl::Add (int32_t value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutIntMethod), (jint) value);
	JNI::ClearExceptions ();
}

void JsonArrayImpl::Add (int64_t value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutLongMethod), (jlong) value);
	JNI::ClearExceptions ();
}

void JsonArrayImpl::Add (uint32_t value) {

	// No uint32 in java, simulate with long
	Add((int64_t) value);
}

void JsonArrayImpl::Add (uint64_t value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutObjectMethod), JavaBigInteger(value).get ());
	JNI::ClearExceptions ();
}

void JsonArrayImpl::Add (double value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutDoubleMethod), (jdouble) value);
	JNI::ClearExceptions ();
}

void JsonArrayImpl::Add (std::shared_ptr<JsonObject> value) {

	std::shared_ptr<JsonObjectImpl> impl = std::dynamic_pointer_cast<JsonObjectImpl> (value);
	if (impl) {
		JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutObjectMethod), impl->mObject);
		JNI::ClearExceptions ();
	}
}

void JsonArrayImpl::Add (std::shared_ptr<JsonArray> value) {

	std::shared_ptr<JsonArrayImpl> impl = std::dynamic_pointer_cast<JsonArrayImpl> (value);
	if (impl) {
		JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutObjectMethod), impl->mObject);
		JNI::ClearExceptions ();
	}
}

int32_t JsonArrayImpl::GetCount () const {

	return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jLengthMethod));
}

bool JsonArrayImpl::HasBoolAtIndex (int32_t idx) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), (jint) idx);
	return obj.IsInstanceOf ("java/lang/Boolean");
}

bool JsonArrayImpl::HasStringAtIndex (int32_t idx) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), (jint) idx);
	return obj.IsInstanceOf ("java/lang/String");
}

bool JsonArrayImpl::HasObjectAtIndex (int32_t idx) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), (jint) idx);
	return obj.IsInstanceOf ("org/json/JSONObject");
}

bool JsonArrayImpl::HasArrayAtIndex (int32_t idx) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), (jint) idx);
	return obj.IsInstanceOf ("org/json/JSONArray");
}

std::string JsonArrayImpl::GetStringAtIndex (int32_t idx) const {

	return JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jOptStringMethod), (jint) idx, JavaString ("").get ()).getString ();
}

bool JsonArrayImpl::GetBoolAtIndex (int32_t idx) const {

	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jOptBooleanMethod), (jint) idx, JNI::ToJboolean (false));
}

int32_t JsonArrayImpl::GetInt32AtIndex (int32_t idx) const {

	return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jOptIntMethod), (jint) idx, (jint) 0);
}

int64_t JsonArrayImpl::GetInt64AtIndex (int32_t idx) const {

	return JNI::GetEnv ()->CallLongMethod (mObject, JNI::JavaMethod (jOptLongMethod), (jint) idx, (jlong) 0);
}

uint32_t JsonArrayImpl::GetUInt32AtIndex (int32_t idx) const {
	// No unsigned type in Java
	int64_t v = GetInt64AtIndex (idx);
	if (v >= std::numeric_limits<uint32_t>::min () && v <= std::numeric_limits<uint32_t>::max ()) {
		return (uint32_t) v;
	}

	return 0;
}

uint64_t JsonArrayImpl::GetUInt64AtIndex (int32_t idx) const {
	// No unsigned type in Java. Such big numbers returns double.
	return (uint64_t) GetDoubleAtIndex (idx);
}

double JsonArrayImpl::GetDoubleAtIndex (int32_t idx) const {

	return JNI::GetEnv ()->CallDoubleMethod (mObject, JNI::JavaMethod (jOptDoubleMethod), (jint) idx, (jdouble) 0.0);
}

std::shared_ptr<JsonObject> JsonArrayImpl::GetObjectAtIndex (int32_t idx) const {

	JavaObject obj = JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptJSONObjectMethod), (jint) idx);
	return std::shared_ptr<JsonObjectImpl> (new JsonObjectImpl (obj.get ()));
}

std::shared_ptr<JsonArray> JsonArrayImpl::GetArrayAtIndex (int32_t idx) const {

	JavaObject obj = JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptJSONArrayMethod), (jint) idx);
	return std::shared_ptr<JsonArrayImpl> (new JsonArrayImpl (obj.get ()));
}

std::string JsonArrayImpl::ToString (bool prettyPrint) const {

	JavaString res;
	if (prettyPrint) {
		res = JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jToStringWithIndentMethod), (jint) 4);
	} else {
		res = JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jToStringMethod)).getString ();
	}
	JNI::ClearExceptions ();
	return res.getString ();
}

std::vector<uint8_t> JsonArrayImpl::ToVector () const {

	std::string str = ToString (false);
	return std::vector<uint8_t> (str.begin (), str.end ());
}

void JsonArrayImpl::IterateItems (std::function<bool (const std::string &value, int32_t idx, JsonDataType type)> handleProperty) const {

	JNIEnv *env = JNI::GetEnv ();

	int32_t count = GetCount ();

	for (int32_t idx = 0; idx < count; ++idx) {
		JavaObject object =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), (jint) idx);

		JsonDataType type = GetJSONDataType (object);
		// additional check for UInt32
		if (type == JsonDataType::Int64) {
			int64_t v = GetInt64AtIndex (idx);
			if (v >= std::numeric_limits<uint32_t>::min () && v <= std::numeric_limits<uint32_t>::max ()) {
				type = JsonDataType::UInt32;
			}
		}

		std::string jsonValue = JavaString::valueOf (object);
		if (JNI::ExceptionCatch()) {
			continue;
		}

		//Call the callback on each property
		if (!handleProperty (jsonValue, idx, type)) {
			break;
		}
	}

}

