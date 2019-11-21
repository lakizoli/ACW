
#ifndef _JNIAPI_H_
#define _JNIAPI_H_

#include <string.h>
#include <jni.h>
#include <android/log.h>
#include <stdlib.h>
#include <string>
#include <tuple>
#include <map>
#include <stdio.h>
#include <libunwind.h>

//////////////////////////////////////////////////////////////////////////////////////////
//Macro definitions
//////////////////////////////////////////////////////////////////////////////////////////
#define LOG_TAG "com.zapp.acw"

#ifdef DEBUG
#	ifdef __ANDROID__
#		define LOG_PREFIX(level)																\
			__android_log_print (level, LOG_TAG, "file: %s (line: %d)", __FILE__, __LINE__);	\
			__android_log_print (level, LOG_TAG, "func: %s", __PRETTY_FUNCTION__);
#	else //__ANDROID__
#		define LOG_PREFIX(level)																\
			printf ("[" #level "] file: %s (line: %d)\n", __FILE__, __LINE__);					\
			printf ("[" #level "] func: %s\n", __PRETTY_FUNCTION__);
#	endif //__ANDROID__
#else
#	define LOG_PREFIX(level)
#endif

#ifdef __ANDROID__
#	define  LOGI(...) { LOG_PREFIX (ANDROID_LOG_INFO)  __android_log_print (ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__); }
#	define  LOGD(...) { LOG_PREFIX (ANDROID_LOG_DEBUG) __android_log_print (ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__); }
#	define  LOGE(...) { LOG_PREFIX (ANDROID_LOG_ERROR) __android_log_print (ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__); }
#else //__ANDROID__
#	define  LOGI(...)  { LOG_PREFIX (i) printf ("[i] {%s} \%s", __VA_ARGS__); }
#	define  LOGD(...)  { LOG_PREFIX (d) printf ("[d] {%s} \%s", __VA_ARGS__); }
#	define  LOGE(...)  { LOG_PREFIX (e) printf ("[e] {%s} \%s", __VA_ARGS__); }
#endif //__ANDROID__

#define CHECKMSG(check, msg)								\
	if (!(check)) {											\
		LOGE ("Assertion occured! message: %s", msg);		\
		assert (check);										\
	}

#define CHECK(check)	CHECKMSG (check, "nothing")

#define CHECKARG(check, ...)								\
	if (!(check)) {											\
		LOGE ("Assertion occured!");						\
		LOGE (__VA_ARGS__);									\
		assert (check);										\
	}

//////////////////////////////////////////////////////////////////////////////////////////
//Forward declarations
//////////////////////////////////////////////////////////////////////////////////////////
// class JavaObject;

//////////////////////////////////////////////////////////////////////////////////////////
//The JNI interface functions
//////////////////////////////////////////////////////////////////////////////////////////
namespace JNI {

//////////////////////////////////////////////////////////////////////////////////////////
//Load functions
//////////////////////////////////////////////////////////////////////////////////////////
int APILoad (JavaVM* vm, const char* loaderClassName);
void APIUnload (JavaVM* vm);

//////////////////////////////////////////////////////////////////////////////////////////
//Basic API functions
//////////////////////////////////////////////////////////////////////////////////////////
JavaVM* GetJavaVM ();
JNIEnv* GetEnv ();
int GetSDKVersion ();
std::string GetStackTrace ();

void SetEventsPath (const char* path);
const char* GetEventsPath ();

//////////////////////////////////////////////////////////////////////////////////////////
//Class functions
//////////////////////////////////////////////////////////////////////////////////////////
jclass FindClass (const char* signature);
inline jclass FindClass (const std::string& signature) {
	return JNI::FindClass (signature.c_str ());
}

jmethodID GetMethod (jclass clazz, const char* method, const char* signature);
inline jmethodID GetMethod (jclass clazz, const std::string& method, const std::string& signature) {
	return GetMethod (clazz, method.c_str (), signature.c_str ());
}

jmethodID GetStaticMethod (jclass clazz, const char* method, const char* signature);
inline jmethodID GetStaticMethod (jclass clazz, const std::string& method, const std::string& signature) {
	return GetStaticMethod (clazz, method.c_str (), signature.c_str ());
}

jfieldID GetField (jclass clazz, const char* field, const char* signature);
inline jfieldID GetField (jclass clazz, const std::string& field, const std::string& signature) {
	return GetField (clazz, field.c_str (), signature.c_str ());
}

jfieldID GetStaticField (jclass clazz, const char* field, const char* signature);
inline jfieldID GetStaticField (jclass clazz, const std::string& field, const std::string& signature) {
	return GetStaticField (clazz, field.c_str (), signature.c_str ());
}

//////////////////////////////////////////////////////////////////////////////////////////
//Reference functions
//
//Internal code!
//Use JavaObject [platformconnector/JavaObject.h] or something similar instead of this, where you can!
//Never use direct call to NewLocalRef () or NewGlobalRef!
//
//////////////////////////////////////////////////////////////////////////////////////////

//Frame functions
void EnsureLocalCapacity (int neededRefCountCapacity);
void PushLocalFrame (int neededRefCount);
void PopLocalFrame ();

struct AutoLocalFrame {
	AutoLocalFrame (int neededRefCount) { PushLocalFrame (neededRefCount); }
	~AutoLocalFrame () { PopLocalFrame (); }
};

//Global reference functions
jobject GlobalReferenceObject (jobject obj, const char* errorMessage = nullptr);

template<class T>
T GlobalReferenceObject (T obj, const char* errorMessage = nullptr) {
	return reinterpret_cast<T> (GlobalReferenceObject (reinterpret_cast<jobject> (obj), errorMessage));
}

bool IsGlobalReference (jobject obj);

template<class T>
bool IsGlobalReference (T obj) {
	return IsGlobalReference (reinterpret_cast<jobject> (obj));
}

void ReleaseGlobalReferencedObject (jobject obj, const char* errorMessage = nullptr);

template<class T>
void ReleaseGlobalReferencedObject (T obj, const char* errorMessage = nullptr) {
	ReleaseGlobalReferencedObject (reinterpret_cast<jobject> (obj), errorMessage);
}

template<class T>
class AutoGlobalRef {
	T obj;
	const char* msg;
public:
	AutoGlobalRef (const char* msg = "nothing") : obj (nullptr), msg (msg) {}
	AutoGlobalRef (T obj, const char* msg = "nothing") : obj (obj), msg (msg) {}
	AutoGlobalRef (const AutoGlobalRef& src) = delete;
	AutoGlobalRef (AutoGlobalRef&& src) : obj (nullptr), msg (nullptr) { *this = std::move (src); }

	~AutoGlobalRef () { ReleaseGlobalReferencedObject (obj, msg); }

	const AutoGlobalRef& operator = (const AutoGlobalRef& src) = delete;
	const AutoGlobalRef& operator = (AutoGlobalRef&& src) {
		ReleaseGlobalReferencedObject (obj, msg);

		obj = src.obj;
		src.obj = nullptr;

		msg = src.msg;
		src.msg = nullptr;

		return *this;
	}

	T get () const { return obj; }
	operator T () const { return obj; }

	void reset (T resetObj = nullptr) { ReleaseGlobalReferencedObject (obj, msg); obj = resetObj; }
};

//Local reference functions
jobject LocalReferenceObject (jobject obj, const char* errorMessage = nullptr);

template<class T>
T LocalReferenceObject (T obj, const char* errorMessage = nullptr) {
	return reinterpret_cast<T> (LocalReferenceObject (reinterpret_cast<jobject> (obj), errorMessage));
}

bool IsLocalReference (jobject obj);

template<class T>
bool IsLocalReference (T obj) {
	return IsLocalReference (reinterpret_cast<jobject> (obj));
}

void ReleaseLocalReferencedObject (jobject obj, const char* errorMessage = nullptr);

template<class T>
void ReleaseLocalReferencedObject (T obj, const char* errorMessage = nullptr) {
	ReleaseLocalReferencedObject (reinterpret_cast<jobject> (obj), errorMessage);
}

template<class T>
class AutoLocalRef {
	T obj;
	const char* msg;
public:
	AutoLocalRef (const char* msg = "nothing") : obj (nullptr), msg (msg) {}
	AutoLocalRef (T obj, const char* msg = "nothing") : obj (obj), msg (msg) {}
	AutoLocalRef (const AutoLocalRef& src) = delete;
	AutoLocalRef (AutoLocalRef&& src) : obj (nullptr), msg (nullptr) { *this = std::move (src); }

	~AutoLocalRef () { ReleaseLocalReferencedObject (obj, msg); }

	const AutoLocalRef& operator = (const AutoLocalRef& src) = delete;
	const AutoLocalRef& operator = (AutoLocalRef&& src) {
		ReleaseLocalReferencedObject (obj, msg);

		obj = src.obj;
		src.obj = nullptr;

		msg = src.msg;
		src.msg = nullptr;

		return *this;
	}

	T get () const { return obj; }
	operator T () const { return obj; }

	void reset (T resetObj = nullptr) { ReleaseLocalReferencedObject (obj, msg); obj = resetObj; }
};

//Debug functions
void DumpReferenceTables ();

//////////////////////////////////////////////////////////////////////////////////////////
//Object call functions
//////////////////////////////////////////////////////////////////////////////////////////
template<class T>
T NewObject (jclass clazz, jmethodID initMethod, ...) {
	va_list params;
	va_start (params, initMethod);

	JNIEnv* env = GetEnv ();
	
	jobject jres = env->NewObjectV (clazz, initMethod, params);

	// Avoid pending exception JNI error during T constructor
	jthrowable exc = env->ExceptionOccurred ();
	if (exc != nullptr) {
		env->ExceptionClear ();
	}

	T res (jres);
	ReleaseLocalReferencedObject (jres);

	if (exc != nullptr) {
		env->Throw (exc);
	}
	
	va_end (params);
	
	return std::move (res);
}

template<class T>
T CallObjectMethod (jobject obj, jmethodID method, ...) {
	va_list params;
	va_start (params, method);

	JNIEnv* env = GetEnv ();

	jobject jres = env->CallObjectMethodV (obj, method, params);

	// Avoid pending exception JNI error during T constructor
	jthrowable exc = env->ExceptionOccurred ();
	if (exc != nullptr) {
		env->ExceptionClear ();
	}

	T res (jres);
	ReleaseLocalReferencedObject (jres);

	if (exc != nullptr) {
		env->Throw (exc);
	}

	va_end (params);
	
	return std::move (res);
}

template<class T>
T CallStaticObjectMethod (jclass clazz, jmethodID method, ...) {
	va_list params;
	va_start (params, method);

	JNIEnv* env = GetEnv ();
	
	jobject jres = env->CallStaticObjectMethodV (clazz, method, params);
	
	// Avoid pending exception JNI error during T constructor
	jthrowable exc = env->ExceptionOccurred ();
	if (exc != nullptr) {
		env->ExceptionClear ();
	}
	
	T res (jres);
	ReleaseLocalReferencedObject (jres);

	if (exc != nullptr) {
		env->Throw (exc);
	}

	va_end (params);

	return std::move (res);
}

//////////////////////////////////////////////////////////////////////////////////////////
//Object field functions
//////////////////////////////////////////////////////////////////////////////////////////
template<class T>
T GetObjectField (jobject obj, jfieldID field) {
	jobject jres = GetEnv ()->GetObjectField (obj, field);
	T res (jres);
	ReleaseLocalReferencedObject (jres);
	
	return std::move (res);
}

template<class T>
T GetStaticObjectField (jclass clazz, jfieldID field) {
	jobject jres = GetEnv ()->GetStaticObjectField (clazz, field);
	T res (jres);
	ReleaseLocalReferencedObject (jres);
	
	return std::move (res);
}

//////////////////////////////////////////////////////////////////////////////////////////
//JNI helper interface
//////////////////////////////////////////////////////////////////////////////////////////
extern const char* JMETHOD;
extern const char* JFIELD;
extern const char* JSTATICMETHOD;
extern const char* JSTATICFIELD;

typedef const char* jClassID[1];
typedef const char* jCallableID[3];

class Caller {
	template<jClassID CLASS, jCallableID ... CALLABLES>
	friend struct CallRegister;

	friend jclass JavaClass (jClassID classID);
	friend jmethodID JavaMethod (jCallableID methodID);
	friend jfieldID JavaField (jCallableID fieldID);
	friend jmethodID JavaStaticMethod (jCallableID methodID);
	friend jfieldID JavaStaticField (jCallableID fieldID);

private:
	std::map<const char**, jclass> _classes;
	std::map<const char**, jmethodID> _methods;
	std::map<const char**, jfieldID> _fields;
	std::map<const char**, jmethodID> _static_methods;
	std::map<const char**, jfieldID> _static_fields;

private:
	Caller () {}

	~Caller () {
		Release ();
	}

	bool IsInited () const {
		return _classes.size () > 0;
	}

	void Init ();
	void Release ();

private:
	static std::map<const char**, const char*>& GetClassesToRegister () {
		static std::map<const char**, const char*> inst;
		return inst;
	}

	static std::map<const char**, std::tuple<const char**, const char*, const char*, const char*>>& GetCallablesToRegister () {
		static std::map<const char**, std::tuple<const char**, const char*, const char*, const char*>> inst;
		return inst;
	}

	template<typename CLASS>
	static void RegisterClass (CLASS clazz) {
		GetClassesToRegister ().emplace (clazz, clazz[0]);
	}

	template<typename CLASS>
	static void RegisterCallable (CLASS clazz) {
		//... nothing to do ...
	}

	template<typename CLASS, typename CALLABLE>
	static void RegisterCallable (CLASS clazz, CALLABLE callable) {
		GetCallablesToRegister ().emplace (callable, std::make_tuple (clazz, callable[0], callable[1], callable[2]));
	}

	template<typename CLASS, typename CALLABLE, typename ... CALLABLES>
	static void RegisterCallable (CLASS clazz, CALLABLE callable, CALLABLES... callables) {
		GetCallablesToRegister ().emplace (callable, std::make_tuple (clazz, callable[0], callable[1], callable[2]));
		RegisterCallable (clazz, callables...);
	}

private:
	static Caller& Get () {
		static Caller inst;
		inst.Init ();
		return inst;
	}

	static jclass Class (jClassID classID) {
		return Get ()._classes.find (classID)->second;
	}

	static jmethodID Method (jCallableID methodID) {
		return Get ()._methods.find (methodID)->second;
	}

	static jfieldID Field (jCallableID fieldID) {
		return Get ()._fields.find (fieldID)->second;
	}

	static jmethodID StaticMethod (jCallableID methodID) {
		return Get ()._static_methods.find (methodID)->second;
	}

	static jfieldID StaticField (jCallableID fieldID) {
		return Get ()._static_fields.find (fieldID)->second;
	}
};

template<jClassID CLASS, jCallableID ... CALLABLES>
struct CallRegister {
	CallRegister () {
		Caller::RegisterClass (CLASS);
		Caller::RegisterCallable (CLASS, CALLABLES...);
	}
};

inline jclass JavaClass (jClassID classID) {
	return Caller::Class (classID);
}

inline jmethodID JavaMethod (jCallableID methodID) {
	return Caller::Method (methodID);
}

inline jfieldID JavaField (jCallableID fieldID) {
	return Caller::Field (fieldID);
}

inline jmethodID JavaStaticMethod (jCallableID methodID) {
	return Caller::Method (methodID);
}

inline jfieldID JavaStaticField (jCallableID fieldID) {
	return Caller::Field (fieldID);
}

inline jboolean ToJboolean (bool value) {
	return (jboolean) (value ? JNI_TRUE : JNI_FALSE);
}

//////////////////////////////////////////////////////////////////////////////////////////
//Exception functions
//////////////////////////////////////////////////////////////////////////////////////////
inline void ClearExceptions () {
	GetEnv ()->ExceptionClear ();
}

inline bool HasException() {
	return GetEnv()->ExceptionCheck() == JNI_TRUE;
}

// Imitate try-catch pattern with automatic exception flag clear
inline bool ExceptionCatch() {
	JNIEnv* env = GetEnv ();
	if (env->ExceptionCheck() == JNI_TRUE) {
		env->ExceptionClear();
		return true;
	}
	return false;
}

void ThrowException (const char* clazz, const char* msg = "no message");

inline void ThrowException (const std::string& clazz, const std::string& msg = std::string ("no message")) {
	ThrowException (clazz.c_str (), msg.c_str ());
}

inline void ThrowNullPointerException (const char* msg = "no message") {
	ThrowException ("java/lang/NullPointerException", msg);
}

inline void ThrowNullPointerException (const std::string& msg = std::string ("no message")) {
	ThrowException ("java/lang/NullPointerException", msg.c_str ());
}

inline void ThrowRuntimeException (const char* msg = "no message") {
	ThrowException ("java/lang/RuntimeException", msg);
}

inline void ThrowRuntimeException (const std::string& msg = std::string ("no message")) {
	ThrowException ("java/lang/RuntimeException", msg.c_str ());
}

std::string StrError (int errnum);

inline void ThrowIOException (int errnum) {
	ThrowException ("java/io/IOException", StrError (errnum).c_str ());
}

} //namespace JNI

#endif //_JNIAPI_H_
