#ifndef JAVAARRAYS_H_INCLUDED
#define JAVAARRAYS_H_INCLUDED

#include <vector>

#include "JavaString.h"

//#include <bxRect.h>
//#include <bxVector3.h>
//#include <bxVector4.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaByteArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaByteArray : public JavaObject {
public:
	JavaByteArray () : JavaObject () { InitWithLength (0); }
	JavaByteArray (int length) { InitWithLength (length); };

	JavaByteArray (const std::vector<uint8_t>& bytes) : JavaObject () { InitWithBytes ((const char*) &bytes[0], (int) bytes.size ()); }
	JavaByteArray (const std::string& str) : JavaObject () { InitWithBytes (&str[0], (int) str.length ()); }
	JavaByteArray (const char* bytes, int length) : JavaObject () { InitWithBytes (bytes, length); }

	JavaByteArray (const JavaByteArray& src) = default;
	JavaByteArray (JavaByteArray&& src) = default;

	JavaByteArray (jobject object);

public:
	JavaByteArray& operator= (const JavaByteArray& src) = default;
	JavaByteArray& operator= (JavaByteArray&& src) = default;

	std::vector<uint8_t> getBytes () const;
	std::string getString () const;
	int length () const;

private:
	void InitWithLength (int length);
	void InitWithBytes (const char* bytes, int length);
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaFloatArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaFloatArray : public JavaObject {
public:
	JavaFloatArray () : JavaObject () { InitWithFloats (nullptr, 0); }

	JavaFloatArray (const std::vector<float>& floats) : JavaObject () { InitWithFloats (&floats[0], (int) floats.size ()); }
	JavaFloatArray (const float* floats, int length) : JavaObject () { InitWithFloats (floats, length); }
//	JavaFloatArray (const glm::vec2& vec2float) : JavaObject () { InitWithFloats ((const float*) &vec2float, 2); }
//	JavaFloatArray (const glm::vec3& vec3float) : JavaObject () { InitWithFloats ((const float*) &vec3float, 3); }
//	JavaFloatArray (const glm::vec4& vec4float) : JavaObject () { InitWithFloats ((const float*) &vec4float, 4); }
//	JavaFloatArray (const glm::mat4x4& mat4x4float) : JavaObject () { InitWithFloats ((const float*) &mat4x4float, 4*4); }
//	JavaFloatArray (const BXRect<float>& rect);

	JavaFloatArray (const JavaFloatArray& src) = default;
	JavaFloatArray (JavaFloatArray&& src) = default;

	JavaFloatArray (jobject object);

public:
	JavaFloatArray& operator= (const JavaFloatArray& src) = default;
	JavaFloatArray& operator= (JavaFloatArray&& src) = default;

	std::vector<float> getVector () const;
//	BXRect<float> getBXRect () const;
//	BXVector3 getBXVector3 () const;
//	BXVector4 getBXVector4 () const;
//	glm::vec2 getVector2 () const;
//	glm::vec3 getVector3 () const;
//	glm::vec4 getVector4 () const;
//	glm::mat4x4 getMatrix4x4 () const;

	int length () const;

private:
	void InitWithFloats (const float* floats, int length);
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaIntArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaIntArray : public JavaObject {
public:
	JavaIntArray () : JavaObject () { InitWithInts (nullptr, 0); }

	JavaIntArray (const std::vector<int>& ints) : JavaObject () { InitWithInts ((const int*) &ints[0], (int) ints.size ()); }
	JavaIntArray (const int* ints, int length) : JavaObject () { InitWithInts (ints, length); }

	JavaIntArray (const JavaIntArray& src) = default;
	JavaIntArray (JavaIntArray&& src) = default;

	JavaIntArray (jobject object);

public:
	JavaIntArray& operator= (const JavaIntArray& src) = default;
	JavaIntArray& operator= (JavaIntArray&& src) = default;

	std::vector<int> getInts () const;
	int length () const;

private:
	void InitWithInts (const int* ints, int length);
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaLongArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaLongArray : public JavaObject {
public:
	JavaLongArray () : JavaObject () { InitWithLongs (nullptr, 0); }

	JavaLongArray (const std::vector<int64_t>& longs) : JavaObject () { InitWithLongs (longs.data (), (int) longs.size ()); }
	JavaLongArray (const int64_t* longs, int length) : JavaObject () { InitWithLongs (longs, length); }

	JavaLongArray (const JavaLongArray& src) = default;
	JavaLongArray (JavaLongArray&& src) = default;

	JavaLongArray (jobject object);

public:
	JavaLongArray& operator= (const JavaLongArray& src) = default;
	JavaLongArray& operator= (JavaLongArray&& src) = default;

	std::vector<int64_t> getLongs () const;
	int length () const;

private:
	void InitWithLongs (const int64_t* ints, int length);
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaStringArray class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaStringArray : public JavaObject {
public:
	JavaStringArray () : JavaObject () { InitWithStrings ({}); }

	JavaStringArray (const std::vector<std::string>& strings) : JavaObject () { InitWithStrings (strings); }

	JavaStringArray (const JavaStringArray& src) = default;
	JavaStringArray (JavaStringArray&& src) = default;

	JavaStringArray (jobject object);

public:
	JavaStringArray& operator= (const JavaStringArray& src) = default;
	JavaStringArray& operator= (JavaStringArray&& src) = default;

	std::vector<std::string> getStrings () const;
	int length () const;

private:
	void InitWithStrings (const std::vector<std::string>& strings);
};

#endif //JAVAARRAYS_H_INCLUDED
