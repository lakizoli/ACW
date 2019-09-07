//
// Created by Laki Zoltán on 2019-09-07.
//

#include <jniapi.h>
#include <JsonArray.hpp>
#include <JsonObject.hpp>
#include <JavaString.h>
#include <JavaContainers.h>
#include <fstream>
#include <vector>

namespace {
//Java class signature
	JNI::jClassID jNetPackConfigClass {"com/zapp/acw/bll/NetPackConfig"};
	JNI::jClassID jNetPackConfigItemClass {"com/zapp/acw/bll/NetPackConfig$NetPackConfigItem"};

//Java method and field signatures
	JNI::jCallableID jNCIInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jLabelField {JNI::JFIELD, "label", "Ljava/lang/String;"};
	JNI::jCallableID jFileIDField {JNI::JFIELD, "fileID", "Ljava/lang/String;"};
	JNI::jCallableID jSizeField {JNI::JFIELD, "size", "I"};

	JNI::jCallableID jNCInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jItemsField {JNI::JFIELD, "_items", "Ljava/util/ArrayList;"};

//Register jni calls
	JNI::CallRegister<jNetPackConfigClass, jNCInitMethod, jItemsField> JNI_NetPackConfig;
	JNI::CallRegister<jNetPackConfigItemClass, jNCIInitMethod, jLabelField, jFileIDField, jSizeField> JNI_NetPackConfigItem;
}

class NetPackConfigItem : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (NetPackConfigItem);

public:
	NetPackConfigItem () {
		JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jNetPackConfigItemClass), JNI::JavaMethod (jNCInitMethod)));
		mObject = JNI::GlobalReferenceObject (jobj.get ());
	}

public:
	void SetLabel (const std::string& label) {
		JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jLabelField), JavaString (label).get ());
	}

	void SetFileID (const std::string& fileID) {
		JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jFileIDField), JavaString (fileID).get ());
	}

	void SetSize (int32_t size) {
		JNI::GetEnv ()->SetIntField (mObject, JNI::JavaField (jSizeField), size);
	}
};

class NetPackConfig : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (NetPackConfig);

public:
	NetPackConfig () {
		JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jNetPackConfigClass), JNI::JavaMethod (jNCInitMethod)));
		mObject = JNI::GlobalReferenceObject (jobj.get ());
	}

public:
	void SetItems (const JavaArrayList<NetPackConfigItem>& items) {
		JNI::GetEnv ()->SetObjectField (mObject, JNI::JavaField (jItemsField), items.get ());
	}
};

extern "C" JNIEXPORT jobject JNICALL Java_com_zapp_acw_bll_NetPackConfig_parse (JNIEnv* env, jclass cls, jstring path) {
	std::ifstream file (JavaString (path).getString (), std::ios::binary | std::ios::in | std::ios::ate);
	if (!file) {
		return nullptr;
	}

	int64_t len = file.tellg ();
	if (!file || len <= 0) {
		return nullptr;
	}

	file.seekg (0, std::ios::beg);
	if (!file) {
		return nullptr;
	}

	std::vector<uint8_t> content (len);
	file.read ((char*) &content[0], len);
	if (!file) {
		return nullptr;
	}

	std::shared_ptr<JsonArray> arr = JsonArray::Parse (content);
	if (arr == nullptr) {
		return nullptr;
	}

	JavaArrayList<NetPackConfigItem> items;
	for (int32_t i = 0, iEnd = arr->GetCount (); i < iEnd; ++i) {
		std::shared_ptr<JsonObject> item = arr->GetObjectAtIndex (i);
		if (item) {
			NetPackConfigItem configItem;
			configItem.SetLabel (item->GetString ("name"));
			configItem.SetFileID (item->GetString ("fileID"));
			configItem.SetSize (item->GetInt32 ("size"));

			items.add (configItem);
		}
	}

	NetPackConfig cfg;
	cfg.SetItems (items);
	return cfg.release ();
}
