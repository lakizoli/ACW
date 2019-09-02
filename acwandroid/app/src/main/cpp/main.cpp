//
// Created by Laki Zoltán on 2019-09-02.
//

#include "jniapi.h"

JNIEXPORT jint JNICALL JNI_OnLoad (JavaVM* vm, void* reserved) {
	return JNI::APILoad (vm, "com/zapp/acw/MainActivity");
}

JNIEXPORT void JNI_OnUnload (JavaVM* vm, void* reserved) {
	JNI::APIUnload (vm);
}
