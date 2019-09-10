#include <functional>
#include "JavaContainers.h"
#include "jniapi.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI helper for Java Containers
////////////////////////////////////////////////////////////////////////////////////////////////////
namespace jni_containers {
//Java class signature
	JNI::jClassID jArrayListClass {"java/util/ArrayList"};
	JNI::jClassID jIteratorClass {"java/util/Iterator"};
	JNI::jClassID jSetClass {"java/util/Set"};
	JNI::jClassID jEntryClass {"java/util/Map$Entry"};
	JNI::jClassID jHashSetClass {"java/util/HashSet"};
	JNI::jClassID jHashMapClass {"java/util/HashMap"};

//Java method and field signatures
	JNI::jCallableID jALInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jALAddMethod {JNI::JMETHOD, "add", "(Ljava/lang/Object;)Z"};
	JNI::jCallableID jALSizeMethod {JNI::JMETHOD, "size", "()I"};
	JNI::jCallableID jALGetMethod {JNI::JMETHOD, "get", "(I)Ljava/lang/Object;"};
	JNI::jCallableID jALClearMethod {JNI::JMETHOD, "clear", "()V"};

	JNI::jCallableID jITHasNextMethod {JNI::JMETHOD, "hasNext", "()Z"};
	JNI::jCallableID jITNextMethod {JNI::JMETHOD, "next", "()Ljava/lang/Object;"};

	JNI::jCallableID jSetIteratorMethod {JNI::JMETHOD, "iterator", "()Ljava/util/Iterator;"};

	JNI::jCallableID jEntryGetKeyMethod {JNI::JMETHOD, "getKey", "()Ljava/lang/Object;"};
	JNI::jCallableID jEntryGetValueMethod {JNI::JMETHOD, "getValue", "()Ljava/lang/Object;"};

	JNI::jCallableID jHSetInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jHSetSizeMethod {JNI::JMETHOD, "size", "()I"};
	JNI::jCallableID jHSetAddMethod {JNI::JMETHOD, "add", "(Ljava/lang/Object;)Z"};
	JNI::jCallableID jHSetContainsMethod {JNI::JMETHOD, "contains", "(Ljava/lang/Object;)Z"};
	JNI::jCallableID jHSetIteratorMethod {JNI::JMETHOD, "iterator", "()Ljava/util/Iterator;"};

	JNI::jCallableID jMapInitMethod {JNI::JMETHOD, "<init>", "()V"};
	JNI::jCallableID jMapPutMethod {JNI::JMETHOD, "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;"};
	JNI::jCallableID jMapSizeMethod {JNI::JMETHOD, "size", "()I"};
	JNI::jCallableID jMapGetMethod {JNI::JMETHOD, "get", "(Ljava/lang/Object;)Ljava/lang/Object;"};
	JNI::jCallableID jMapEntrySetMethod {JNI::JMETHOD, "entrySet", "()Ljava/util/Set;"};
	JNI::jCallableID jMapContainsKeyMethod {JNI::JMETHOD, "containsKey", "(Ljava/lang/Object;)Z"};

//Register jni calls
	JNI::CallRegister<jArrayListClass, jALInitMethod, jALAddMethod, jALSizeMethod, jALGetMethod, jALClearMethod> JNI_JavaArrayList;
	JNI::CallRegister<jIteratorClass, jITHasNextMethod, jITNextMethod> JNI_JavaIterator;
	JNI::CallRegister<jSetClass, jSetIteratorMethod> JNI_JavaSet;
	JNI::CallRegister<jEntryClass, jEntryGetKeyMethod, jEntryGetValueMethod> JNI_JavaEntry;
	JNI::CallRegister<jHashSetClass, jHSetInitMethod, jHSetSizeMethod, jHSetAddMethod, jHSetContainsMethod, jHSetIteratorMethod> JNI_JavaHashSet;
	JNI::CallRegister<jHashMapClass, jMapInitMethod, jMapPutMethod, jMapSizeMethod, jMapGetMethod, jMapEntrySetMethod, jMapContainsKeyMethod> JNI_JavaHashMap;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaIterator class
////////////////////////////////////////////////////////////////////////////////////////////////////
bool JavaIterator::hasNext () const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jni_containers::jITHasNextMethod));
}

JavaObject JavaIterator::next () const {
	return JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jni_containers::jITNextMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaSet class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaIterator JavaSet::iterator () const {
	return JNI::CallObjectMethod<JavaIterator> (mObject, JNI::JavaMethod (jni_containers::jSetIteratorMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaEntry class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaObject JavaEntry::key () const {
	return JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jni_containers::jEntryGetKeyMethod));
}

JavaObject JavaEntry::value () const {
	return JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jni_containers::jEntryGetValueMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaHashSet class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaHashSet::JavaHashSet () {
	JNI::AutoLocalRef<jobject> jobj = JNI::GetEnv ()->NewObject (JNI::JavaClass (jni_containers::jHashSetClass), JNI::JavaMethod (jni_containers::jHSetInitMethod));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

int JavaHashSet::size () const {
	return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jni_containers::jHSetSizeMethod));
}

void JavaHashSet::add (const JavaObject& obj) {
	JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jni_containers::jHSetAddMethod), obj.get ());
}

bool JavaHashSet::contains (const JavaObject& obj) const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jni_containers::jHSetContainsMethod), obj.get ());
}

JavaIterator JavaHashSet::iterator () const {
	return JNI::CallObjectMethod<JavaIterator> (mObject, JNI::JavaMethod (jni_containers::jHSetIteratorMethod));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaHashMap class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaHashMap::JavaHashMap () : JavaObject () {
	JNI::AutoLocalRef<jobject> jobj = JNI::GetEnv ()->NewObject (JNI::JavaClass (jni_containers::jHashMapClass), JNI::JavaMethod (jni_containers::jMapInitMethod));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

int JavaHashMap::size () const {
	return JNI::GetEnv ()->CallIntMethod (mObject, JNI::JavaMethod (jni_containers::jMapSizeMethod));
}

void JavaHashMap::put (const JavaObject& key, const JavaObject& value) {
	JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jni_containers::jMapPutMethod), key.get (), value.get ());
}

JavaObject JavaHashMap::at (const JavaObject& key) const {
	return JNI::CallObjectMethod<JavaObject> (mObject, JNI::JavaMethod (jni_containers::jMapGetMethod), key.get ());
}

bool JavaHashMap::containsKey (const JavaObject& key) const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jni_containers::jMapContainsKeyMethod), key.get ());
}

void JavaHashMap::iterate (std::function<bool (JavaObject key, JavaObject value)> callback) const {
	if (mObject == nullptr || callback == nullptr || size () <= 0) {
		return;
	}

	JavaSet entrySet = JNI::CallObjectMethod<JavaSet> (mObject, JNI::JavaMethod (jni_containers::jMapEntrySetMethod));
	if (entrySet.get () != nullptr) {
		JavaIterator iter = entrySet.iterator ();
		if (iter.get () != nullptr) {
			while (iter.hasNext ()) {
				JNI::AutoLocalFrame frame (8);

				JavaEntry entry = iter.next ();
				if (entry.get () == nullptr) {
					continue;
				}

				if (!callback (entry.key (), entry.value ())) {
					break;
				}
			}
		}
	}
}