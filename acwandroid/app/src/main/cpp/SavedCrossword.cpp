//
// Created by Laki Zoltán on 2019-09-02.
//

#include "jniapi.h"

extern "C" JNIEXPORT void JNICALL Java_com_zapp_acw_bll_SavedCrossword_deleteUsedWordsFromDB (JNIEnv *env, jclass cls, jstring packageName, jobject words) {
//	std::shared_ptr<UsedWords> usedWords = UsedWords::Create ([packagePath UTF8String]);
//	if (usedWords) {
//		__block std::set<std::wstring> updatedWords = usedWords->GetWords ();
//
//		[_words enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
//		NSData *objData = [obj dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
//		std::wstring wordToErase ((const wchar_t*) [objData bytes], [objData length] / sizeof (wchar_t));
//		updatedWords.erase (wordToErase);
//	}];
//
//		UsedWords::Update ([packagePath UTF8String], updatedWords);
//	}
}