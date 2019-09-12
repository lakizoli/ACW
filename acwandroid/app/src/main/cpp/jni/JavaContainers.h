#ifndef JAVACONTAINERS_H_INCLUDED
#define JAVACONTAINERS_H_INCLUDED

#include "JavaObject.h"
#include "vector"

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI helper for Java Containers
////////////////////////////////////////////////////////////////////////////////////////////////////
namespace jni_containers {
//Java class signature
	extern JNI::jClassID jArrayListClass;

//Java method and field signatures
	extern JNI::jCallableID jALInitMethod;
	extern JNI::jCallableID jALAddMethod;
	extern JNI::jCallableID jALSizeMethod;
	extern JNI::jCallableID jALGetMethod;
	extern JNI::jCallableID jALClearMethod;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaIterator class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaIterator : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaIterator);

public:
	bool hasNext () const;
	JavaObject next () const;

private:
	JavaIterator () = delete;
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaSet class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaSet : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaSet);

public:
	JavaIterator iterator () const;

private:
	JavaSet () = delete;
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaEntry class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaEntry : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaEntry);

public:
	JavaObject key () const;
	JavaObject value () const;

private:
	JavaEntry () = delete;
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaHashMap class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaHashSet : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaHashSet);

public:
	JavaHashSet ();

public:
	int size () const;
	void add (const JavaObject& obj);
	bool contains (const JavaObject& obj) const;
	JavaIterator iterator () const;
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaHashMap class
////////////////////////////////////////////////////////////////////////////////////////////////////
class JavaHashMap : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaHashMap);

public:
	JavaHashMap ();

public:
	int size () const;
	void put (const JavaObject& key, const JavaObject& value);
	JavaObject at (const JavaObject& key) const;
	bool containsKey (const JavaObject& key) const;
	void iterate (std::function<bool (JavaObject key, JavaObject value)> callback) const;
};

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaArrayList class
////////////////////////////////////////////////////////////////////////////////////////////////////
template<class T = JavaObject>
class JavaArrayList : public JavaObject {
	DECLARE_DEFAULT_JAVAOBJECT (JavaArrayList);

public:
	JavaArrayList<T> () : JavaObject () {
		JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jni_containers::jArrayListClass), JNI::JavaMethod (jni_containers::jALInitMethod)));
		mObject = JNI::GlobalReferenceObject (jobj.get ());
	}

	template<class N>
	static JavaArrayList<T> createFromVector (const std::vector<N>& vec) {
		JavaArrayList<T> jArr;
		for (const N& item : vec) {
			jArr.add (T (item).get ());
		}
		return jArr;
	}

	template<class N>
	static JavaArrayList<T> createFromVector (const std::vector<N>& vec, std::function<T (const N& item)> getJavaItem) {
		JavaArrayList<T> jArr;
		for (const N& item : vec) {
			jArr.add (getJavaItem (item));
		}
		return jArr;
	}

public:
	int size () const { return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jni_containers::jALSizeMethod)); }
	bool add (const T& what) { return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jni_containers::jALAddMethod), what.get ()); }
	T itemAt (int index) const { return JNI::CallObjectMethod<T> (mObject, JNI::JavaMethod (jni_containers::jALGetMethod), index); }
	void clear () { JNI::GetEnv ()->CallVoidMethod (mObject, JNI::JavaMethod (jni_containers::jALClearMethod)); }

	template<class N>
	std::vector<N> toVector (N (T::* getItem) () const) const {
		std::vector<N> res;

		if (mObject != nullptr) {
			for (int i = 0, iEnd = size (); i < iEnd; ++i) {
				T item = itemAt (i);
				res.push_back ((item.*getItem) ());
			}
		}

		return res;
	}
};

#endif //JAVACONTAINERS_H_INCLUDED
