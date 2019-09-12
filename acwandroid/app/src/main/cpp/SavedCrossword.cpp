//
// Created by Laki Zoltán on 2019-09-02.
//

#include <set>
#include <memory>
#include "jniapi.h"
#include "UsedWords.hpp"
#include "Crossword.hpp"
#include "JavaString.h"
#include "JavaContainers.h"
#include "ObjectStore.hpp"
#include <cw.hpp>
#include <adb.hpp>

namespace {
//Java class signature
	JNI::jClassID jSavedCrosswordClass {"com/zapp/acw/bll/SavedCrossword"};

//Java method and field signatures
	JNI::jCallableID jNativeObjIDField {JNI::JFIELD, "nativeObjID", "I"};

//Register jni calls
	JNI::CallRegister<jSavedCrosswordClass, jNativeObjIDField> JNI_SavedCrossword;
}

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
			std::wstring wordToErase ((const wchar_t *) &bytes[0], bytes.size () / sizeof (wchar_t));
			updatedWords.erase (wordToErase);
		}

		UsedWords::Update (packagePath, updatedWords);
	}
}

extern "C" JNIEXPORT jint JNICALL Java_com_zapp_acw_bll_SavedCrossword_loadDB (JNIEnv *env, jclass clazz, jstring path) {
	std::shared_ptr<Crossword> cw = Crossword::Load (JavaString (path).getString ());
	return ObjectStore<Crossword>::Get ().Add (cw);
}

extern "C" JNIEXPORT void JNICALL Java_com_zapp_acw_bll_SavedCrossword_unloadDB (JNIEnv *env, jclass clazz, jint native_obj_id) {
	ObjectStore<Crossword>::Get ().Remove (native_obj_id);
}

enum CWCellType : uint32_t {
	CWCellType_Unknown					= 0x0000,

	CWCellType_SingleQuestion			= 0x0001,
	CWCellType_DoubleQuestion			= 0x0002,
	CWCellType_Spacer					= 0x0004,
	CWCellType_Letter					= 0x0008,

	CWCellType_Start_TopDown_Right		= 0x0010,
	CWCellType_Start_TopDown_Left		= 0x0020,
	CWCellType_Start_TopDown_Bottom		= 0x0040,

	CWCellType_Start_TopRight			= 0x0080,
	CWCellType_Start_FullRight			= 0x0100,
	CWCellType_Start_BottomRight		= 0x0200,

	CWCellType_Start_LeftRight_Top		= 0x0400,
	CWCellType_Start_LeftRight_Bottom	= 0x0800,

	CWCellType_HasValue					= 0x0FF8
};

enum CWCellSeparator : uint32_t {
	CWCellSeparator_None	= 0x0000,

	CWCellSeparator_Left	= 0x0001,
	CWCellSeparator_Top		= 0x0002,
	CWCellSeparator_Right	= 0x0004,
	CWCellSeparator_Bottom	= 0x0008,

	CWCellSeparator_All		= 0x000F
};

static std::shared_ptr<Cell> getCell (int32_t native_obj_id, uint32_t row, uint32_t col) {
	std::shared_ptr<Crossword> cw = ObjectStore<Crossword>::Get ().Get (native_obj_id);
	if (cw == nullptr) {
		return nullptr;
	}

	std::shared_ptr<Grid> grid = cw->GetGrid ();
	if (grid == nullptr) {
		return nullptr;
	}

	if (row >= grid->GetHeight ()) {
		return nullptr;
	}

	if (col >= grid->GetWidth ()) {
		return nullptr;
	}

	return grid->GetCell (row, col);
}

extern "C" JNIEXPORT jint JNICALL Java_com_zapp_acw_bll_SavedCrossword_getCellTypeInRow (JNIEnv* env, jobject thiz, jint row, jint col) {
	int32_t native_obj_id = JNI::GetEnv ()->GetIntField (thiz, JNI::JavaField (jNativeObjIDField));

	std::shared_ptr<Cell> cell = getCell (native_obj_id, row, col);
	if (cell == nullptr) {
		return CWCellType_Unknown;
	}

	//Spacer cell
	if (cell->IsEmpty ()) {
		return CWCellType_Spacer;
	}

	//Question cell
	if (cell->IsFlagSet (CellFlags::Question)) {
		std::shared_ptr<QuestionInfo> qInfo = cell->GetQuestionInfo ();
		if (qInfo == nullptr) {
			return CWCellType_Unknown;
		}

		const std::vector<QuestionInfo::Question>& questions = qInfo->GetQuestions ();
		switch (questions.size ()) {
			case 1:
				return CWCellType_SingleQuestion;
			case 2:
				return CWCellType_DoubleQuestion;
			default:
				break;
		}

		return CWCellType_Spacer;
	}

	//Handle start letters
	if (cell->IsFlagSet (CellFlags::StartCell)) {
		uint32_t cellTypeRes = CWCellType_Unknown;

		for (const CellPos& qPos : cell->GetStartCellQuestionPositions ()) {
			std::shared_ptr<Cell> qCell = getCell (native_obj_id, qPos.row, qPos.col);
			if (qCell == nullptr) {
				continue;
			}

			const CellPos& cPos = cell->GetPos ();
			if (cPos.row < qPos.row && cPos.col == qPos.col) { //Start cell is above question cell
				cellTypeRes |= CWCellType_Start_LeftRight_Top;
			} else if (cPos.row > qPos.row && cPos.col == qPos.col) { //Start cell is below question cell
				std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
				if (qInfo == nullptr) {
					continue;
				}

				const std::vector<QuestionInfo::Question>& qs = qInfo->GetQuestions ();
				if (qs.size () >= 1) {
					switch (qs[qs.size () - 1].dir) {
						case QuestionInfo::Direction::BottomDown:
							cellTypeRes |= CWCellType_Start_TopDown_Bottom;
							break;
						case QuestionInfo::Direction::BottomRight:
							cellTypeRes |= CWCellType_Start_LeftRight_Bottom;
							break;
						default:
							break;
					}
				}
			} else if (cPos.row == qPos.row && cPos.col < qPos.col) { //Start cell is on the left side of question cell
				cellTypeRes |= CWCellType_Start_TopDown_Left;
			} else if (cPos.row == qPos.row && cPos.col > qPos.col) { //Start cell is on the right side of question cell
				std::shared_ptr<QuestionInfo> qInfo = qCell->GetQuestionInfo ();
				if (qInfo == nullptr) {
					continue;
				}

				const std::vector<QuestionInfo::Question>& qs = qInfo->GetQuestions ();
				if (qs.size () > 1) {
					switch (qs[0].dir) {
						case QuestionInfo::Direction::RightDown:
							cellTypeRes |= CWCellType_Start_TopDown_Right;
							break;
						case QuestionInfo::Direction::Right:
							cellTypeRes |= CWCellType_Start_TopRight;
							break;
						default:
							break;
					}

					if (qs[1].dir == QuestionInfo::Direction::Right) {
						cellTypeRes |= CWCellType_Start_BottomRight;
					}
				} else if (qs.size () == 1) {
					switch (qs[0].dir) {
						case QuestionInfo::Direction::RightDown:
							cellTypeRes |= CWCellType_Start_TopDown_Right;
							break;
						case QuestionInfo::Direction::Right:
							cellTypeRes |= CWCellType_Start_FullRight;
							break;
						default:
							break;
					}
				}
			}
		}

		return cellTypeRes;
	}

	return CWCellType_Letter;
}

extern "C" JNIEXPORT jboolean JNICALL Java_com_zapp_acw_bll_SavedCrossword_isStartCell (JNIEnv* env, jobject thiz, jint row, jint col) {
	int32_t native_obj_id = JNI::GetEnv ()->GetIntField (thiz, JNI::JavaField (jNativeObjIDField));

	std::shared_ptr<Cell> cell = getCell (native_obj_id, row, col);
	return (cell != nullptr && cell->IsFlagSet (CellFlags::StartCell));
}

extern "C" JNIEXPORT jstring JNICALL Java_com_zapp_acw_bll_SavedCrossword_getCellsQuestion (JNIEnv* env, jobject thiz, jint row, jint col, jint questionIndex) {
	int32_t native_obj_id = JNI::GetEnv ()->GetIntField (thiz, JNI::JavaField (jNativeObjIDField));

	std::shared_ptr<Cell> cell = getCell (native_obj_id, row, col);
	if (cell != nullptr && cell->IsFlagSet (CellFlags::Question)) {
		std::shared_ptr<QuestionInfo> qInfo = cell->GetQuestionInfo ();
		if (qInfo != nullptr) {
			const std::vector<QuestionInfo::Question>& qs = qInfo->GetQuestions ();
			if (qs.size () > questionIndex) {
				const std::wstring& qStr = qs[questionIndex].question;
				uint32_t len = qStr.length () * sizeof (wchar_t);
				return (jstring) JavaString ((const char*) qStr.c_str (), (int32_t) len, "UTF-16LE").release ();
			}
		}
	}

	return nullptr;
}

extern "C" JNIEXPORT jstring JNICALL Java_com_zapp_acw_bll_SavedCrossword_getCellsValue (JNIEnv* env, jobject thiz, jint row, jint col) {
	int32_t native_obj_id = JNI::GetEnv ()->GetIntField (thiz, JNI::JavaField (jNativeObjIDField));

	std::shared_ptr<Cell> cell = getCell (native_obj_id, row, col);
	if (cell != nullptr && cell->IsFlagSet (CellFlags::Value)) {
		std::wstring chStr;
		chStr += cell->GetValue ();
		uint32_t len = chStr.length () * sizeof (wchar_t);
		return (jstring) JavaString ((const char*) chStr.c_str (), (int32_t) len, "UTF-16LE").release ();
	}

	return nullptr;
}

extern "C" JNIEXPORT jint JNICALL Java_com_zapp_acw_bll_SavedCrossword_getCellsSeparators (JNIEnv* env, jobject thiz, jint row, jint col) {
	int32_t native_obj_id = JNI::GetEnv ()->GetIntField (thiz, JNI::JavaField (jNativeObjIDField));

	uint32_t seps = CWCellSeparator_None;

	std::shared_ptr<Cell> cell = getCell (native_obj_id, row, col);
	if (cell != nullptr) {
		if (cell->IsFlagSet (CellFlags::LeftSeparator)) {
			seps |= CWCellSeparator_Left;
		}

		if (cell->IsFlagSet (CellFlags::TopSeparator)) {
			seps |= CWCellSeparator_Top;
		}

		std::shared_ptr<Cell> rightCell = getCell (native_obj_id, row, col + 1);
		if (rightCell != nullptr && rightCell->IsFlagSet (CellFlags::LeftSeparator)) { //If the right neighbour has a left separator!
			seps |= CWCellSeparator_Right;
		}

		std::shared_ptr<Cell> bottomCell = getCell (native_obj_id, row + 1, col);
		if (bottomCell != nullptr && bottomCell->IsFlagSet (CellFlags::TopSeparator)) { //If the bottom neighbour has a top separator!
			seps |= CWCellSeparator_Bottom;
		}
	}

	return seps;
}

extern "C" JNIEXPORT jobject JNICALL Java_com_zapp_acw_bll_SavedCrossword_getUsedKeys (JNIEnv* env, jobject thiz) {
	int32_t native_obj_id = JNI::GetEnv ()->GetIntField (thiz, JNI::JavaField (jNativeObjIDField));
	std::shared_ptr<Crossword> cw = ObjectStore<Crossword>::Get ().Get (native_obj_id);
	if (cw == nullptr) {
		return nullptr;
	}

	JavaHashSet usedKeys;
	for (wchar_t ch :  cw->GetUsedKeys ()) {
		std::wstring chStr;
		chStr += ch;
		uint32_t len = chStr.length () * sizeof (wchar_t);
		JavaString jStr = JavaString ((const char*) chStr.c_str (), (int32_t) len, "UTF-16LE");
		usedKeys.add (jStr);
	}

	return usedKeys.release ();
}