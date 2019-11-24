//
// Created by Laki Zoltán on 2019-09-04.
//

#include <JavaFile.hpp>

extern "C" JNIEXPORT jboolean JNICALL Java_com_zapp_acw_FileUtils_deleteRecursive (JNIEnv*, jclass, jstring path) {
	JavaFile file (JavaString (path).getString ());
	return (jboolean) file.deleteRecursively ();
}

extern "C" JNIEXPORT jboolean JNICALL Java_com_zapp_acw_FileUtils_copyRecursive (JNIEnv*, jclass, jstring source_path, jstring dest_path) {
	JavaFile file (JavaString (source_path).getString ());
	return (jboolean) file.copyRecursively (JavaString (dest_path).getString ());
}

extern "C" JNIEXPORT jboolean JNICALL Java_com_zapp_acw_FileUtils_moveTo (JNIEnv*, jclass, jstring source_path, jstring dest_path) {
	JavaFile file (JavaString (source_path).getString ());
	return (jboolean) file.moveTo (JavaString (dest_path).getString ());
}
