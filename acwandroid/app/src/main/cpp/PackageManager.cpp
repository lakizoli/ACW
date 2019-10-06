//
// Created by Laki Zoltán on 2019-09-04.
//

#include <set>
#include <vector>
#include <jniapi.h>
#include <unzip.h>
#include <JavaString.h>
#include <BasicInfo.hpp>
#include <JavaFile.hpp>
#include <JavaContainers.h>
#include <cw.hpp>
#include <UsedWords.hpp>
#include "Package.hpp"
#include "CardList.hpp"
#include "ObjectStore.hpp"
#include "GeneratorInfo.hpp"

namespace {
//Java class signature
	JNI::jClassID jPackageManagerClass {"com/zapp/acw/bll/PackageManager"};
	JNI::jClassID jProgressCallbackClass {"com/zapp/acw/bll/PackageManager$ProgressCallback"};

//Java method and field signatures
	JNI::jCallableID jPackageStateURLMethod {JNI::JMETHOD, "packageStateURL", "(Ljava/lang/String;)Ljava/lang/String;"};
	JNI::jCallableID jTrimQuestionFieldMethod {JNI::JMETHOD, "trimQuestionField", "(Ljava/lang/String;)Ljava/lang/String;"};
	JNI::jCallableID jTrimSolutionFieldMethod {JNI::JMETHOD, "trimSolutionField", "(Ljava/lang/String;Ljava/util/ArrayList;Ljava/util/HashMap;)Ljava/lang/String;"};

	JNI::jCallableID jProgressApplyMethod {JNI::JMETHOD, "apply", "(F)Z"};

//Register jni calls
	JNI::CallRegister<jPackageManagerClass, jPackageStateURLMethod, jTrimQuestionFieldMethod, jTrimSolutionFieldMethod> JNI_PackageManager;
	JNI::CallRegister<jProgressCallbackClass, jProgressApplyMethod> JNI_ProgressCallback;

//Local types
	class ProgressCallBack : public JavaObject {
		DECLARE_DEFAULT_JAVAOBJECT (ProgressCallBack);

	public:
		bool apply (float progress) const {
			return JNI::GetEnv ()->CallBooleanMethod (mObject, JNI::JavaMethod (jProgressApplyMethod), (jfloat) progress);
		}
	};
}

extern "C" JNIEXPORT void JNICALL Java_com_zapp_acw_bll_PackageManager_unzipPackage (JNIEnv* env, jclass clazz, jstring package_path, jstring dest_path) {
	unzFile pack = unzOpen (JavaString (package_path).getString ().c_str ());
	if (pack == nullptr) {
		LOGE ("PackageManager::unzipPackage - Cannot open package to unzip!");
		return;
	}

	bool first = true;
	while (true) {
		//Locate the next file
		int32_t nextFileRes = first ? unzGoToFirstFile (pack) : unzGoToNextFile (pack);
		if (nextFileRes != UNZ_OK && nextFileRes != UNZ_END_OF_LIST_OF_FILE) {
			LOGE ("PackageManager::unzipPackage - Cannot locate file in package to unzip!");
			return;
		}
		first = false;

		//Read file info
		unz_file_info fileInfo;
		char fileNameBuffer[512];
		if (unzGetCurrentFileInfo (pack, &fileInfo, fileNameBuffer, 512, nullptr, 0, nullptr, 0) != UNZ_OK) {
			LOGE ("PackageManager::unzipPackage - Cannot read file info in package to unzip!");
			return;
		}

		if (fileInfo.size_filename >= 512) {
			LOGE ("PackageManager::unzipPackage - Filename too long in package to unzip!");
			return;
		}

		std::string fileName (&fileNameBuffer[0], &fileNameBuffer[fileInfo.size_filename]);

		//Unpack file to the destination
		if (unzOpenCurrentFile (pack) != UNZ_OK) {
			LOGE ("PackageManager::unzipPackage - Cannot open file in package to unzip!");
			return;
		}

		std::string destFilePath = JavaString (dest_path).getString () + "/" + fileName;
		FILE* destFile = fopen (destFilePath.c_str (), "wb");
		if (destFile == nullptr) {
			LOGE ("PackageManager::unzipPackage - Cannot create file at destination!");
			return;
		}

		int32_t chunkLen = 1024 * 1024;
		std::vector<uint8_t> buffer (chunkLen);
		int32_t readLen = 0;
		while ((readLen = unzReadCurrentFile (pack, &buffer[0], chunkLen)) != 0) {
			if (fwrite (&buffer[0], 1, readLen, destFile) != readLen) {
				LOGE ("PackageManager::unzipPackage - Cannot write file at destination!");
				return;
			}
		}

		fclose (destFile);

		if (unzCloseCurrentFile (pack) != UNZ_OK) {
			LOGE ("PackageManager::unzipPackage - Cannot close file in package to unzip!");
			return;
		}

		//Check last file
		if (nextFileRes == UNZ_END_OF_LIST_OF_FILE) { //If we reached the last file in the last cycle, then break
			break;
		}
	}

	unzClose (pack);
}

static std::vector<std::shared_ptr<BasicInfo>> readBasicPackageInfos (const std::string& dbDir) {
	JavaFile fileDB (dbDir);
	std::vector<std::shared_ptr<BasicInfo>> result;
	for (const std::string& dirURL : fileDB.list ()) {
		std::string itemPath = dbDir + "/" + dirURL;
		if (JavaFile (itemPath).isDirectory ()) {
			std::shared_ptr<BasicInfo> basicInfo = BasicInfo::Create (itemPath);
			if (basicInfo) {
				result.push_back (basicInfo);
			}
		}
	}

	return result;
}

extern "C" JNIEXPORT jobject JNICALL Java_com_zapp_acw_bll_PackageManager_extractLevel1Info (JNIEnv* env, jobject thiz, jstring dbDir) {
	//Prepare packages in database
	std::vector<std::shared_ptr<BasicInfo>> basicInfos = readBasicPackageInfos (JavaString (dbDir).getString ());

	//Extract package's level1 informations
	JavaArrayList<Package> result;
	for (std::shared_ptr<BasicInfo> db : basicInfos) {
		Package pack;
		pack.SetPath (db->GetPath ());
		pack.SetName (db->GetPackageName ());

		JavaArrayList<Deck> decks;
		for (auto& it : db->GetDecks ()) {
			Deck deck;

			deck.SetPackagePath (pack.GetPath ());
			deck.SetDeckID (it.first);
			deck.SetName (it.second->name.c_str ());

			decks.add (deck);
		}
		pack.SetDecks (decks);

		JavaString stateURL = JNI::CallObjectMethod<JavaString> (thiz, JNI::JavaMethod (jPackageStateURLMethod), JavaString (db->GetPath ()).get ());

		GameState state;
		state.LoadFrom (stateURL.getString ());
		pack.SetState (state);

		result.add (pack);
	}

	return result.release ();
}

extern "C" JNIEXPORT jobject JNICALL Java_com_zapp_acw_bll_PackageManager_collectSavedCrosswordsOfPackage (JNIEnv* env, jobject thiz, jstring packageName, jstring jPackageDir) {
	std::string packageDir = JavaString (jPackageDir).getString ();

	JavaArrayList<SavedCrossword> arr;
	for (const std::string& child : JavaFile (packageDir).list ()) {
		JavaFile childFile (packageDir + "/" + child);
		if (!childFile.isDirectory () && child.rfind (".cw") == child.length () - 3) {
//			LOGD ("child: %s", childFile.getAbsolutePath ().c_str ());
//			LOGD ("file name: %s", child.c_str ());

			std::shared_ptr<Crossword> loadedCW = Crossword::Load (childFile.getAbsolutePath ());
			if (loadedCW != nullptr) {
				SavedCrossword cw;
				cw.SetPath (childFile.getAbsolutePath ());
				cw.SetPackageName (JavaString (packageName).getString ());
				cw.SetName (loadedCW->GetName ());

				std::shared_ptr<Grid> grid = loadedCW->GetGrid ();
				cw.SetWidth (grid->GetWidth ());
				cw.SetHeight (grid->GetHeight ());

				JavaHashSet words;
				for (const std::wstring& word : loadedCW->GetWords ()) {
					uint32_t len = word.length () * sizeof (wchar_t);
					JavaString jWord ((const char*) word.c_str (), len, "UTF-32LE");
					words.add (jWord);
				}

				cw.SetWords (words);

				arr.add (cw);
			}
		}
	}

	return arr.release ();
}

extern "C" JNIEXPORT jobject JNICALL Java_com_zapp_acw_bll_PackageManager_collectGeneratorInfo (JNIEnv* env, jobject thiz, jobject jDecks) {
	JavaArrayList<Deck> decks (jDecks);
	if (decks.get () == nullptr || decks.size () < 1) {
		return nullptr;
	}

	//Collect most decks with same modelID (all of them have to be the same, but not guaranteed!)
	std::string packagePath;
	std::vector<std::shared_ptr<CardList>> cardListsOfDecks;
	std::map<uint64_t, std::set<uint64_t>> deckIndicesByModelID;
	for (int idx = 0, iEnd = decks.size (); idx < iEnd; ++idx) {
		Deck deck = decks.itemAt (idx);
		if (packagePath.empty ()) {
			packagePath = deck.GetPackagePath ();
		}

		std::shared_ptr<CardList> cardList = CardList::Create (deck.GetPackagePath (), deck.GetDeckID ());
		cardListsOfDecks.push_back (cardList);
		if (cardList) {
			const std::map<uint64_t, std::shared_ptr<CardList::Card>>& cards = cardList->GetCards ();
			if (cards.size () > 0) {
				uint64_t modelID = cards.begin ()->second->modelID;
				auto it = deckIndicesByModelID.find (modelID);
				if (it == deckIndicesByModelID.end ()) {
					deckIndicesByModelID.emplace (modelID, std::set<uint64_t> {(uint64_t) idx});
				} else {
					it->second.insert ((uint64_t) idx);
				}
			}
		}
	}

	if (deckIndicesByModelID.empty () || cardListsOfDecks.size () != decks.size ()) {
		return nullptr;
	}

	bool foundOneModelID = false;
	uint64_t maxCount = 0;
	uint64_t choosenModelID = 0;
	for (auto it : deckIndicesByModelID) {
		if (it.second.size () > maxCount) {
			choosenModelID = it.first;
			maxCount = it.second.size ();
			foundOneModelID = true;
		}
	}

	if (!foundOneModelID) {
		return nullptr;
	}

	//Read used words of package
	std::shared_ptr<UsedWords> usedWords = UsedWords::Create (packagePath);

	//Collect generator info
	GeneratorInfo info;

	auto itDeckIndices = deckIndicesByModelID.find (choosenModelID);
	if (itDeckIndices == deckIndicesByModelID.end ()) {
		return nullptr;
	}

	bool isFirstDeck = true;
	for (uint64_t deckIdx : itDeckIndices->second) {
		std::shared_ptr<CardList> cardList = cardListsOfDecks[deckIdx];
		if (cardList == nullptr) {
			continue;
		}

		info.AddDeck (decks.itemAt (deckIdx));

		if (isFirstDeck) { //Collect fields from first deck only
			isFirstDeck = false;

			for (auto it : cardList->GetFields ()) {
				Field field;

				field.SetName (it.second->name);
				field.SetIdx (it.second->idx);

				info.AddField (field);
			}
		}

		for (auto it : cardList->GetCards ()) {
			Card card;

			card.SetCardID (it.second->cardID);
			card.SetNoteID (it.second->noteID);
			card.SetModelID (it.second->modelID);

			for (const std::string& fieldValue : it.second->fields) {
				card.AddFieldValue (fieldValue);
			}

			card.SetSolutionFieldValue (it.second->solutionField);

			info.AddCard (card);
		}
	}

	if (usedWords != nullptr) {
		for (const std::wstring& word : usedWords->GetWords ()) {
			uint32_t len = word.length () * sizeof (wchar_t);
			JavaString jWord ((const char*) word.c_str (), len, "UTF-32LE");
			info.AddUsedWord (jWord);
		}
	}

	return info.release ();
}

extern "C" JNIEXPORT void JNICALL Java_com_zapp_acw_bll_PackageManager_reloadUsedWords (JNIEnv* env, jobject thiz, jstring package_path, jobject jInfo) {
	GeneratorInfo info (jInfo);
	info.ClearUsedWords ();

	std::shared_ptr<UsedWords> usedWords = UsedWords::Create (JavaString (package_path).getString ());

	if (usedWords != nullptr) {
		for (const std::wstring& word : usedWords->GetWords ()) {
			uint32_t len = word.length () * sizeof (wchar_t);
			JavaString jWord ((const char*) word.c_str (), len, "UTF-32LE");
			info.AddUsedWord (jWord);
		}
	}
}

extern "C" JNIEXPORT jboolean JNICALL Java_com_zapp_acw_bll_PackageManager_generateWithInfo (JNIEnv* env, jobject thiz, jobject jInfo, jobject progress_callback) {
	JNI::AutoLocalRef<jobject> obj (thiz);

	if (jInfo == nullptr) {
		return false;
	}

	GeneratorInfo info (jInfo);
	JavaArrayList<Deck> decks = info.GetDecks ();

	if (decks.size () < 1) {
		return false;
	}

	std::string packagePath = decks.itemAt (0).GetPackagePath ();

	std::set<uint64_t> deckIDs;
	for (int i = 0, iEnd = decks.size (); i < iEnd; ++i) {
		deckIDs.insert (decks.itemAt (i).GetDeckID ());
	}

	std::vector<std::wstring> questionFieldValues;
	std::vector<std::wstring> solutionFieldValues;
	JavaHashSet solutionFieldFilter;

	JavaArrayList<Card> cards = info.GetCards ();
	JavaArrayList<JavaString> splitArray = info.GetSplitArray ();
	JavaHashMap solutionFixes = info.GetSolutionFixes ();

	for (int idx = 0, iEnd = cards.size (); idx < iEnd; ++idx) {
		Card card = cards.itemAt (idx);

		JavaArrayList<JavaString> fieldValues = card.GetFieldValues ();
		if (fieldValues.get () == nullptr || fieldValues.size () <= info.GetSolutionFieldIndex () || fieldValues.size () <= info.GetQuestionFieldIndex ()) {
			continue;
		}

		JavaString origSolutionVal = fieldValues.itemAt (info.GetSolutionFieldIndex ()).toLowerCase ();
		JavaString solutionVal = JNI::CallObjectMethod<JavaString> (obj, JNI::JavaMethod (jTrimSolutionFieldMethod), origSolutionVal.get (), splitArray.get (), solutionFixes.get ());
		if (solutionVal.length () <= 0) {
			continue;
		}

		JavaString questionVal = fieldValues.itemAt (info.GetQuestionFieldIndex ());
		questionVal = JNI::CallObjectMethod<JavaString> (obj, JNI::JavaMethod (jTrimQuestionFieldMethod), questionVal.get ());
		if (questionVal.length () <= 0) {
			continue;
		}

		if (solutionFieldFilter.contains (solutionVal)) { //Filter duplicated solution values
			continue;
		}
		solutionFieldFilter.add (solutionVal);
//		LOGD ("%s |||| %s", origSolutionVal.getString ().c_str (), solutionVal.getString ().c_str ());

		std::vector<uint8_t> bytes = solutionVal.getBytesWithEncoding ("UTF-32LE");
		solutionFieldValues.push_back (std::wstring ((const wchar_t*) &bytes[0], bytes.size () / sizeof (wchar_t)));

		bytes = questionVal.getBytesWithEncoding ("UTF-32LE");
		questionFieldValues.push_back (std::wstring ((const wchar_t*) &bytes[0], bytes.size () / sizeof (wchar_t)));
	}


	if (questionFieldValues.size () <= 0 || solutionFieldValues.size () <= 0 || questionFieldValues.size () != solutionFieldValues.size ()) {
		return false;
	}

	std::vector<std::wstring> usedWordValues;
	JavaArrayList<JavaString> jUsedWords = info.GetUsedWords ();
	for (int idx = 0, iEnd = jUsedWords.size (); idx < iEnd; ++idx) {
		JavaString word = jUsedWords.itemAt (idx);
		std::vector<uint8_t> bytes = word.getBytesWithEncoding ("UTF-32LE");
		usedWordValues.push_back (std::wstring ((const wchar_t*) &bytes[0], bytes.size () / sizeof (wchar_t)));
	}

	struct Query : public QueryWords {
		std::vector<std::wstring>& _words;
		std::function<void (const std::set<std::wstring>& values)> _updater;

		virtual uint32_t GetCount () const override final { return (uint32_t) _words.size (); }
		virtual const std::wstring& GetWord (uint32_t idx) const override final { return _words[idx]; }
		virtual void Clear () override final { _words.clear (); }
		virtual void UpdateWithSet (const std::set<std::wstring>& values) override {
			if (_updater) {
				_updater (values);
			}
		}
		Query (std::vector<std::wstring>& words, std::function<void (const std::set<std::wstring>&)> updater = nullptr) :
			_words (words), _updater (updater) {}
	};

	std::string packagePathForUsedWords = packagePath;
	auto updateUsedWords = [&packagePathForUsedWords] (const std::set<std::wstring>& usedWords) -> void {
		UsedWords::Update (packagePathForUsedWords, usedWords);
	};

	auto progressHandler = [progressCallback = ProgressCallBack (progress_callback)] (float progress) -> bool {
		return progressCallback.apply (progress); //true == continue generation
	};

	std::shared_ptr<Generator> gen = Generator::Create (packagePath,
														info.GetCrosswordName (),
														(uint32_t) info.GetWidth (),
														(uint32_t) info.GetHeight (),
														std::make_shared<Query> (questionFieldValues),
														std::make_shared<Query> (solutionFieldValues),
														std::make_shared<Query> (usedWordValues, updateUsedWords),
														progressHandler);
	if (gen == nullptr) {
		return false;
	}

	std::shared_ptr<Crossword> cw = gen->Generate ();
	if (cw == nullptr) {
		return false;
	}

	if (cw->GetWords().size () <= 0) { //We generated an empty crossword...
		return false;
	}

	std::string fileName = JavaUUID::randomUUID ().toString () + ".cw";
	std::string fileUrl = packagePath + "/" + fileName;
	if (!cw->Save (fileUrl)) {
		return false;
	}

	return true;
}
