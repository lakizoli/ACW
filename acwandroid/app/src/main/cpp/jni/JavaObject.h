#ifndef JAVAOBJECT_H_INCLUDED
#define JAVAOBJECT_H_INCLUDED

#include "jniapi.h"

class JavaObject
{
public:
	JavaObject () : mObject (nullptr) {
		// LOGI ("JavaObject::JavaObject () - obj: nullptr, this: 0x%08x", (int)this);
	}

	JavaObject (const JavaObject& src) : mObject (nullptr) {
		// LOGI ("JavaObject::JavaObject (const JavaObject& src) - obj: 0x%08x, this: 0x%08x, src: 0x%08x", (int)src.mObject, (int)this, (int)&src);
		*this = src;
	}
	JavaObject (JavaObject&& src) : mObject (nullptr) {
		// LOGI ("JavaObject::JavaObject (JavaObject&& src) - obj: 0x%08x, this: 0x%08x, src: 0x%08x", (int)src.mObject, (int)this, (int)&src);
		*this = std::move (src);
	}
	JavaObject (jobject obj) : mObject (nullptr) {
		// LOGI ("JavaObject::JavaObject (jobject obj) - obj: 0x%08x, this: 0x%08x", (int)obj, (int)this);
		if (obj != nullptr)
			mObject = JNI::GlobalReferenceObject (obj, "JavaObject::JavaObject (jobject)");
	}

	virtual ~JavaObject () {
		// LOGI ("JavaObject::~JavaObject () - obj: 0x%08x, this: 0x%08x", (int)mObject, (int)this);
		JNI::ReleaseGlobalReferencedObject (mObject, "JavaObject::~JavaObject ()");
		mObject = nullptr;
	}

	JavaObject& operator = (const JavaObject& src) {
		//Clear old reference
		JNI::ReleaseGlobalReferencedObject (mObject, "JavaObject::operator = (const JavaObject&)");
		mObject = nullptr;

		//Reference new object
		mObject = JNI::GlobalReferenceObject (src.mObject, "JavaObject::operator = (const JavaObject&)");

		return *this;
	}
	JavaObject& operator = (JavaObject&& src) {
		//Clear old reference
		JNI::ReleaseGlobalReferencedObject (mObject, "JavaObject::operator = (JavaObject&&)");
		mObject = nullptr;

		//Move content
		mObject = src.mObject;
		src.mObject = nullptr;

		return *this;
	}

	jobject get () const {
		return mObject;
	}
	jobject release () {
		jobject res = JNI::LocalReferenceObject (mObject);
		JNI::ReleaseGlobalReferencedObject (mObject, "JavaObject::release ()");
		mObject = nullptr;
		return res;
	}

	inline bool IsInstanceOf (const char* signature) {
		JNI::AutoLocalRef<jclass> clazz (JNI::FindClass (signature));
		return clazz != nullptr && mObject != nullptr ? JNI::GetEnv ()->IsInstanceOf (mObject, clazz) == JNI_TRUE : false;
	}
	inline bool IsInstanceOf (jclass clazz) {
		return clazz != nullptr && mObject != nullptr ? JNI::GetEnv ()->IsInstanceOf (mObject, clazz) == JNI_TRUE : false;
	}

protected:
	jobject mObject;
};

#define DECLARE_DEFAULT_JAVAOBJECT_WITH_PARENT(cls, parent)						\
public:																			\
	cls (const cls& src) = default;												\
	cls (cls&& src) = default;													\
																				\
	cls (const JavaObject& src) : parent (src) {}								\
	cls (JavaObject&& src) : parent (std::move (src)) {}						\
	cls (jobject value) : parent (value) {}										\
																				\
public:																			\
	cls& operator = (const cls& src) = default;									\
	cls& operator = (cls&& src) = default;										\
																				\
private:

#define DECLARE_DEFAULT_JAVAOBJECT(cls) DECLARE_DEFAULT_JAVAOBJECT_WITH_PARENT(cls, JavaObject)

#endif //JAVAOBJECT_H_INCLUDED
