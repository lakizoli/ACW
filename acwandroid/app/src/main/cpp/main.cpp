//
// Created by Laki Zoltán on 2019-09-02.
//

#include <JavaFile.hpp>

JNIEXPORT jint JNICALL JNI_OnLoad (JavaVM* vm, void*) {
	return JNI::APILoad (vm, "com/zapp/acw/MainActivity");
}

JNIEXPORT void JNI_OnUnload (JavaVM* vm, void*) {
	JNI::APIUnload (vm);
}

extern "C" JNIEXPORT void JNICALL Java_com_zapp_acw_bll_NetLogger_setEventsPath (JNIEnv*, jclass, jstring events_path) {
	std::string path = JavaString (events_path).getString ();

	JavaFile dir (path);
	if (!dir.exists ()) {
		dir.mkdirs ();
	}

	JNI::SetEventsPath (path.c_str ());
}