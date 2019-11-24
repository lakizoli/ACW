#include <jniapi.h>
#include <JavaString.h>
#include <JavaTypes.h>
#include <JavaArrays.h>
#include <sstream>
#include <JavaContainers.h>
#include "JavaJSONObjectImpl.hpp"
#include "JavaJSONArrayImpl.hpp"

namespace
{
	JNI::jClassID jJSONObjectClass{"org/json/JSONObject"};

	JNI::jCallableID jInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jInitStringMethod {JNI::JMETHOD, "<init>", "(Ljava/lang/String;)V"};

	JNI::jCallableID jOptMethod {JNI::JMETHOD, "opt", "(Ljava/lang/String;)Ljava/lang/Object;"};

	JNI::jCallableID jPutBooleanMethod {JNI::JMETHOD, "put", "(Ljava/lang/String;Z)Lorg/json/JSONObject;"};
	JNI::jCallableID jPutIntMethod {JNI::JMETHOD, "put", "(Ljava/lang/String;I)Lorg/json/JSONObject;"};
	JNI::jCallableID jPutLongMethod {JNI::JMETHOD, "put", "(Ljava/lang/String;J)Lorg/json/JSONObject;"};
	JNI::jCallableID jPutDoubleMethod {JNI::JMETHOD, "put", "(Ljava/lang/String;D)Lorg/json/JSONObject;"};
	JNI::jCallableID jPutObjectMethod {JNI::JMETHOD, "put", "(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;"};

	JNI::jCallableID jOptStringMethod {JNI::JMETHOD, "optString", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"};
	JNI::jCallableID jOptBooleanMethod {JNI::JMETHOD, "optBoolean", "(Ljava/lang/String;Z)Z"};
	JNI::jCallableID jOptIntMethod {JNI::JMETHOD, "optInt", "(Ljava/lang/String;I)I"};
	JNI::jCallableID jOptLongMethod {JNI::JMETHOD, "optLong", "(Ljava/lang/String;J)J"};
	JNI::jCallableID jOptDoubleMethod {JNI::JMETHOD, "optDouble", "(Ljava/lang/String;D)D"};
	JNI::jCallableID jOptJSONObjectMethod {JNI::JMETHOD, "optJSONObject", "(Ljava/lang/String;)Lorg/json/JSONObject;"};
	JNI::jCallableID jOptJSONArrayMethod {JNI::JMETHOD, "optJSONArray", "(Ljava/lang/String;)Lorg/json/JSONArray;"};

	JNI::jCallableID jToStringMethod {JNI::JMETHOD, "toString", "()Ljava/lang/String;"};
	JNI::jCallableID jToStringWithIndentMethod {JNI::JMETHOD, "toString", "(I)Ljava/lang/String;"};

	JNI::jCallableID jKeysMethod {JNI::JMETHOD, "keys", "()Ljava/util/Iterator;"};


	JNI::CallRegister<jJSONObjectClass, jInitMethod, jInitStringMethod, jOptMethod, jPutBooleanMethod,
		jPutIntMethod, jPutLongMethod, jPutDoubleMethod, jPutObjectMethod, jOptStringMethod, jOptBooleanMethod,
		jOptIntMethod, jOptLongMethod, jOptDoubleMethod, jOptJSONObjectMethod, jOptJSONArrayMethod, jToStringMethod,
		jToStringWithIndentMethod, jKeysMethod> JNI_JSONObject;

}

////////////////////////////////////////////////////////////////////////////////////////////////////
// JSONObject
////////////////////////////////////////////////////////////////////////////////////////////////////

std::shared_ptr<JsonObject> JsonObject::Create () {

	JNIEnv *env = JNI::GetEnv ();
	JNI::AutoLocalRef<jobject> jobj (env->NewObject (JNI::JavaClass (jJSONObjectClass), JNI::JavaMethod (jInitMethod)));
	return std::shared_ptr<JsonObjectImpl> (new JsonObjectImpl (jobj));
}

std::shared_ptr<JsonObject> JsonObject::Parse (const std::vector<uint8_t> &json) {

	return JsonObject::Parse (std::string (json.begin (), json.end ()));
}

std::shared_ptr<JsonObject> JsonObject::Parse (const std::string &json) {

	if (json.size () <= 0) {
		return nullptr;
	}

	//Parse JSON
	JNIEnv *env = JNI::GetEnv ();
	JNI::AutoLocalRef<jobject> jobj (env->NewObject (JNI::JavaClass (jJSONObjectClass), JNI::JavaMethod (jInitStringMethod), JavaString (json).get ()));

	if (JNI::ExceptionCatch()) {
		return nullptr;
	}

	return std::shared_ptr<JsonObjectImpl> (new JsonObjectImpl (jobj));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// JSONObjectImpl
////////////////////////////////////////////////////////////////////////////////////////////////////

JsonObjectImpl::JsonObjectImpl (jobject internalObject) {

	mObject = JNI::GlobalReferenceObject (internalObject);
}

bool JsonObjectImpl::HasNumber (const std::string &key) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), JavaString (key).get ());
	return obj.IsInstanceOf ("java/lang/Number");
}

void JsonObjectImpl::Add (const std::string &key, const std::string &value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutObjectMethod), JavaString (key).get (), JavaString (value).get ());
	JNI::ClearExceptions ();
}

void JsonObjectImpl::Add (const std::string &key, bool value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutBooleanMethod), JavaString (key).get (), JNI::ToJboolean (value));
	JNI::ClearExceptions ();
}

void JsonObjectImpl::Add (const std::string &key, int32_t value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutIntMethod), JavaString (key).get (), (jint) value);
	JNI::ClearExceptions ();
}

void JsonObjectImpl::Add (const std::string &key, int64_t value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutLongMethod), JavaString (key).get (), (jlong) value);
	JNI::ClearExceptions ();
}

void JsonObjectImpl::Add (const std::string &key, uint32_t value) {

	// No uint32 in java, simulate with long
	Add(key, (int64_t) value);
}

void JsonObjectImpl::Add (const std::string &key, uint64_t value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutObjectMethod), JavaString (key).get (), JavaBigInteger(value).get ());
	JNI::ClearExceptions ();
}

void JsonObjectImpl::Add (const std::string &key, double value) {

	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutDoubleMethod), JavaString (key).get (), (jdouble) value);
	JNI::ClearExceptions ();
}

void JsonObjectImpl::Add (const std::string &key, std::shared_ptr<JsonObject> value) {

	std::shared_ptr<JsonObjectImpl> impl = std::dynamic_pointer_cast<JsonObjectImpl> (value);
	if (impl) {
		JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutObjectMethod), JavaString (key).get (), impl->mObject);
		JNI::ClearExceptions ();
	}
}

void JsonObjectImpl::Add (const std::string &key, std::shared_ptr<JsonArray> value) {

	std::shared_ptr<JsonArrayImpl> impl = std::dynamic_pointer_cast<JsonArrayImpl> (value);
	if (impl) {
		JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jPutObjectMethod), JavaString (key).get (), impl->mObject);
		JNI::ClearExceptions ();
	}
}

bool JsonObjectImpl::HasString (const std::string &key) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), JavaString (key).get ());
	return obj.IsInstanceOf ("java/lang/String");
}

bool JsonObjectImpl::HasBool (const std::string &key) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), JavaString (key).get ());
	return obj.IsInstanceOf ("java/lang/Boolean");
}

bool JsonObjectImpl::HasObject (const std::string &key) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), JavaString (key).get ());
	return obj.IsInstanceOf ("org/json/JSONObject");
}

bool JsonObjectImpl::HasArray (const std::string &key) const {

	JavaObject obj =  JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), JavaString (key).get ());
	return obj.IsInstanceOf ("org/json/JSONArray");
}

std::string JsonObjectImpl::GetString (const std::string &key) const {

	return JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jOptStringMethod), JavaString (key).get (), JavaString ("").get ()).getString ();
}

bool JsonObjectImpl::GetBool (const std::string &key) const {

	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jOptBooleanMethod), JavaString (key).get (), JNI::ToJboolean (false));
}

int32_t JsonObjectImpl::GetInt32 (const std::string &key) const {

	return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jOptIntMethod), JavaString (key).get (), (jint) 0);
}

int64_t JsonObjectImpl::GetInt64 (const std::string &key) const {

	return JNI::GetEnv ()->CallLongMethod (mObject, JNI::JavaMethod (jOptLongMethod), JavaString (key).get (), (jlong) 0);
}

uint32_t JsonObjectImpl::GetUInt32 (const std::string &key) const {
	// No unsigned type in Java
	int64_t v = GetInt64 (key);
	if (v >= std::numeric_limits<uint32_t>::min () && v <= std::numeric_limits<uint32_t>::max ()) {
		return (uint32_t) v;
	}

	return 0;
}

uint64_t JsonObjectImpl::GetUInt64 (const std::string &key) const {
	// No unsigned type in Java. Such big numbers returns double.
	return (uint64_t) GetDouble (key);
}

double JsonObjectImpl::GetDouble (const std::string &key) const {

	return JNI::GetEnv ()->CallDoubleMethod (mObject, JNI::JavaMethod (jOptDoubleMethod), JavaString (key).get (), (jdouble) 0.0);
}

std::shared_ptr<JsonObject> JsonObjectImpl::GetObject (const std::string &key) const {

	JavaObject obj = JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptJSONObjectMethod), JavaString (key).get ());
	return std::shared_ptr<JsonObjectImpl> (new JsonObjectImpl (obj.get ()));
}

std::shared_ptr<JsonArray> JsonObjectImpl::GetArray (const std::string &key) const {

	JavaObject obj = JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptJSONArrayMethod), JavaString (key).get ());
	return std::shared_ptr<JsonArrayImpl> (new JsonArrayImpl (obj.get ()));
}

std::string JsonObjectImpl::ToString (bool prettyPrint) const {

	JavaString res;
	if (prettyPrint) {
		res = JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jToStringWithIndentMethod), (jint) 4);
	} else {
		res = JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jToStringMethod));
	}
	JNI::ClearExceptions ();
	return res.getString ();
}

std::vector<uint8_t> JsonObjectImpl::ToVector () const {

	std::string str = ToString (false);
	return std::vector<uint8_t> (str.begin (), str.end ());
}

void JsonObjectImpl::IterateProperties (std::function<bool (const std::string &key, const std::string &value, JsonDataType type)> handleProperty) const {

	JavaIterator iterator = JNI::CallObjectMethod<JavaIterator> (mObject, JNI::JavaMethod (jKeysMethod));

	while (iterator.hasNext ()) {
		JavaString key = JavaString(iterator.next ());
		JavaObject value = JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jOptMethod), key.get ());

		// Guess type
		JsonDataType type = GetJSONDataType (value);
		// additional check for UInt32
		if (type == JsonDataType::Int64) {
			int64_t v = GetInt64 (key.getString ());
			if (v >= std::numeric_limits<uint32_t>::min () && v <= std::numeric_limits<uint32_t>::max ()) {
				type = JsonDataType::UInt32;
			}
		}

		std::string jsonValue = JavaString::valueOf (value);
		if (JNI::ExceptionCatch ()) {
			continue;
		}

		//Call the callback on each property
		if (!handleProperty (key.getString (), jsonValue, type)) {
			break;
		}
	}
}

