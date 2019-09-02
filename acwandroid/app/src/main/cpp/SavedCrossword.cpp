//
// Created by Laki Zoltán on 2019-09-02.
//

#include <set>
#include "jniapi.h"
#include "UsedWords.hpp"
#include "JavaString.h"
#include "JavaContainers.h"

extern "C" JNIEXPORT void JNICALL Java_com_zapp_acw_bll_SavedCrossword_deleteUsedWordsFromDB (JNIEnv *env, jclass cls, jstring jPackagePath, jobject jWords) {
	std::string packagePath = JavaString (jPackagePath).getString ();
	std::shared_ptr<UsedWords> usedWords = UsedWords::Create (packagePath);
	if (usedWords) {
		std::set<std::wstring> updatedWords = usedWords->GetWords ();

		JavaSet words (jWords);
		JavaIterator itWords = words.iterator ();
		while (itWords.hasNext ()) {
			JavaString word (itWords.next ());
			std::vector<uint8_t> bytes = word.getBytesWithEncoding ("UTF-16LE");
			std::wstring wordToErase ((const wchar_t *) &bytes[0],
									  bytes.size () / sizeof (wchar_t));
			updatedWords.erase (wordToErase);
		}

		UsedWords::Update (packagePath, updatedWords);
	}
}