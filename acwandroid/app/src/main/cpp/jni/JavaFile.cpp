//
//  JavaFile.cpp
//  Connector
//
//  Created by Szauka Attila on 2018. 11. 20..
//  Copyright © 2018. Graphisoft. All rights reserved.
//

#include "jniapi.h"
#include "JavaObject.h"
#include "JavaFile.hpp"
#include "JavaString.h"
#include <deque>
#include <cstdio>
#include <errno.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI helper for JavaFile class
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace {
	//Java class signature
	JNI::jClassID jFileClass {"java/io/File"};

	//Java method and field signatures
	JNI::jCallableID jInitFileStringMehod {JNI::JMETHOD, "<init>", "(Ljava/io/File;Ljava/lang/String;)V"};
	JNI::jCallableID jInitFileJustStringMehod {JNI::JMETHOD, "<init>", "(Ljava/lang/String;)V"};
	JNI::jCallableID jGetAbsolutePathMethod {JNI::JMETHOD, "getAbsolutePath", "()Ljava/lang/String;"};
	JNI::jCallableID jIsExistshMethod {JNI::JMETHOD, "exists", "()Z"};
	JNI::jCallableID jCreateNewFilehMethod {JNI::JMETHOD, "createNewFile", "()Z"};
	JNI::jCallableID jMkdirMethod {JNI::JMETHOD, "mkdir", "()Z"};
	JNI::jCallableID jMkdirsMethod {JNI::JMETHOD, "mkdirs", "()Z"};
	JNI::jCallableID jGetParentMethod {JNI::JMETHOD, "getParent", "()Ljava/lang/String;"};
	JNI::jCallableID jLastModifiedMethod {JNI::JMETHOD, "lastModified", "()J"};
	JNI::jCallableID jLengthMethod {JNI::JMETHOD, "length", "()J"};
	JNI::jCallableID jIsDirectoryMethod {JNI::JMETHOD, "isDirectory", "()Z"};
	JNI::jCallableID jListMethod {JNI::JMETHOD, "list", "()[Ljava/lang/String;"};
	JNI::jCallableID jGetNameMethod {JNI::JMETHOD, "getName", "()Ljava/lang/String;"};
	JNI::jCallableID jSetLastModifiedMethod {JNI::JMETHOD, "setLastModified", "(J)Z"};

	//Register jni calls
	JNI::CallRegister<jFileClass, jInitFileStringMehod, jInitFileJustStringMehod, jGetAbsolutePathMethod, jIsExistshMethod, jCreateNewFilehMethod,
		jMkdirMethod, jMkdirsMethod, jGetParentMethod, jLastModifiedMethod, jLengthMethod, jIsDirectoryMethod, jListMethod, jGetNameMethod,
		jSetLastModifiedMethod> JNI_JavaFile;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// C++ implementation of the JavaFile class
////////////////////////////////////////////////////////////////////////////////////////////////////
JavaFile::JavaFile (const JavaFile& jFile, const std::string& fileName) {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jFileClass), JNI::JavaMethod (jInitFileStringMehod), jFile.get (), JavaString (fileName).get ()));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

JavaFile::JavaFile (const std::string& fileName) {
	JNI::AutoLocalRef<jobject> jobj (JNI::GetEnv ()->NewObject (JNI::JavaClass (jFileClass), JNI::JavaMethod (jInitFileJustStringMehod), JavaString (fileName).get ()));
	mObject = JNI::GlobalReferenceObject (jobj.get ());
}

std::string JavaFile::getAbsolutePath () const {
	return JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jGetAbsolutePathMethod)).getString ();
}

std::string JavaFile::getParent () const {
	return JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jGetParentMethod)).getString ();
}

bool JavaFile::exists () const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jIsExistshMethod));
}

bool JavaFile::createNewFile () const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jCreateNewFilehMethod));
}

bool JavaFile::mkdir () const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jMkdirMethod));
}

bool JavaFile::mkdirs () const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jMkdirsMethod));
}

bool JavaFile::setLastModified (int64_t time) const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jSetLastModifiedMethod), time * 1000);
}

int64_t JavaFile::lastModified () const {
	return JNI::GetEnv ()->CallLongMethod (mObject, JNI::JavaMethod (jLastModifiedMethod)) / 1000;
}

int64_t JavaFile::length () const {
	return JNI::GetEnv ()->CallLongMethod (mObject, JNI::JavaMethod (jLengthMethod));
}

bool JavaFile::isDirectory () const {
	return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jIsDirectoryMethod));
}

std::vector<std::string> JavaFile::list () const {
	return JNI::CallObjectMethod<JavaStringArray> (mObject, JNI::JavaMethod (jListMethod)).getStrings ();
}

std::string JavaFile::getName () const {
	return JNI::CallObjectMethod<JavaString> (mObject, JNI::JavaMethod (jGetNameMethod)).getString ();
}

bool JavaFile::deleteRecursively () const {
	if (!exists ()) {
		return true;
	}

	//Delete recursively
	std::deque<std::string> queue;
	queue.emplace_back (getAbsolutePath ());

	while (!queue.empty ()) {
		std::string itemPath = queue.front ();
		queue.pop_front ();

		JavaFile item (itemPath);
		if (item.isDirectory ()) {
			std::vector<std::string> children = item.list ();
			if (!children.empty ()) {
				queue.emplace_front (itemPath);
				for (const std::string& child : children) {
					queue.emplace_front (itemPath + "/" + child);
				}
				continue;
			}
		}

		//delete file or empty directory
		if (std::remove (itemPath.c_str ()) != 0) {
			return false;
		}
	}

	return true;
}

bool JavaFile::moveTo (const std::string& destPath) const {
	std::string sourcePath = getAbsolutePath ();
	int32_t res = std::rename (sourcePath.c_str (), destPath.c_str ());
	if (res != 0 && errno == EXDEV) { //Cross device move not supported!
		if (!copyRecursively (destPath)) { //Copy source to the target
			return false;
		}

		if (!deleteRecursively ()) { //Delete original files
			return false;
		}

		res = 0; //succeeded
	}
	return res == 0;
}

bool JavaFile::copyRecursively (const std::string& destPath) const {
	if (!exists ()) {
		return false;
	}

	std::string origPath = getAbsolutePath ();

	std::deque<std::string> queue;
	queue.emplace_back (origPath);

	while (!queue.empty ()) {
		std::string copySourcePath = queue.front ();
		queue.pop_front ();

		size_t remainingCount = copySourcePath.length () - origPath.length ();
		std::string copyDestPath = destPath + (remainingCount > 0 ? copySourcePath.substr (copySourcePath.length () - remainingCount) : std::string ());

		JavaFile copySource (copySourcePath);
		if (copySource.isDirectory ()) { //copy directory
			//Add children to copy list
			for (const std::string& child : copySource.list ()) {
				queue.emplace_front (copySourcePath + "/" + child);
			}

			//Create empty dir at destination
			if (!JavaFile (copyDestPath).mkdir ()) {
				return false;
			}
		} else { //copy file
			struct AutoCloseFile {
				std::FILE*& file;
				AutoCloseFile (std::FILE*& file) : file (file) {}
				~AutoCloseFile () { std::fclose (file); file = nullptr; }
			};

			int64_t len = copySource.length ();
			std::FILE* src = std::fopen (copySourcePath.c_str (), "rb");
			if (src == nullptr) {
				return false;
			}

			AutoCloseFile autoCloseSource (src);

			std::FILE* dest = std::fopen (copyDestPath.c_str (), "wb");
			if (dest == nullptr) {
				return false;
			}

			AutoCloseFile autoCloseDest (dest);

			int64_t chunkSize = 1024*1024;
			int64_t chunkCount = len / chunkSize;
			if (len % chunkSize) {
				++chunkCount;
			}

			std::vector<uint8_t> buffer (chunkSize);
			for (int64_t chunk = 0; chunk < chunkCount; ++chunk) {
				int64_t readCount = chunk == chunkCount - 1 ? len - chunk * chunkSize : chunkSize;

				if (std::fread (&buffer[0], sizeof (uint8_t), readCount, src) != readCount) {
					return false;
				}

				if (std::fwrite (&buffer[0], sizeof (uint8_t), readCount, dest) != readCount) {
					return false;
				}
			}
		}
	}

	return true;
}









