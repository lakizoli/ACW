#ifndef _JAVA_STRING_H_INCLUDED
#define _JAVA_STRING_H_INCLUDED

#include "JavaObject.h"
#include "jniapi.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI helper for JavaString class
////////////////////////////////////////////////////////////////////////////////////////////////////
namespace jni_string {
//Java class signature
	extern JNI::jClassID jStringClass;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaString class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaString : public JavaObject {
public:
	JavaString ();

	JavaString (const std::string& str, const char* encoding = "UTF-8") : JavaObject () { InitWithEncoding (str.c_str (), str.length (), encoding); }
	JavaString (const char* bytes, int length, const char* encoding = "UTF-8") : JavaObject () { InitWithEncoding (bytes, length, encoding); }

	JavaString (const JavaString& src) = default;
	JavaString (JavaString&& src) = default;

	JavaString (const JavaObject& src) : JavaObject (src) {}
	JavaString (JavaObject&& src) : JavaObject (std::move (src)) {}

	JavaString (jstring obj);
	JavaString (jobject obj);

public:
	JavaString& operator= (const JavaString& src) = default;
	JavaString& operator= (JavaString&& src) = default;

	std::string getString () const;
	std::string getStringWithEncoding (const char* encoding = "UTF-8") const;

	std::vector<uint8_t> getBytes () const;
	std::vector<uint8_t> getBytesWithEncoding (const char* encoding) const;

	static std::string valueOf (JavaObject javaObject);

private:
	void InitWithEncoding (const char* bytes, int length, const char* encoding);
};

#endif
