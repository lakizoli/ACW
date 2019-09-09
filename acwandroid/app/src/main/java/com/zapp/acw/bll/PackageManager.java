package com.zapp.acw.bll;

import android.content.Context;
import android.util.Log;

import com.zapp.acw.FileUtils;

import java.io.File;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.TreeMap;

import static android.icu.text.Normalizer.YES;

public final class PackageManager {
	public Context applicationContext = null;

	private String _overriddenDocURL = null;
	private String _overriddenDatabaseURL = null;

	//region Singleton construction
	private static PackageManager inst = new PackageManager ();

	private PackageManager () {
	}

	public static PackageManager sharedInstance () {
		return inst;
	}
	//endregion

	//region Collecting packages
	public void setOverriddenDocumentPath (String url) {
		_overriddenDocURL = url;
	}

	public void setOverriddenDatabasePath (String url) {
		_overriddenDatabaseURL = url;
	}

	private static native void unzipPackage(String packagePath, String destPath);

	public void unzipDownloadedPackage (String downloadedPackagePath, String packageName) {
		//Check destination (if already exists we have to delete it!)
		String packagesPath = databasePath ();
		String destPath = FileUtils.pathByAppendingPathComponent (packagesPath, packageName);

		if (new File (destPath).exists ()) {
			if (!FileUtils.deleteRecursive (destPath)) {
				Log.e ("PackageManager", "unzipDownloadedPackage - Cannot unzip package, because its already exist, and cannot be removed!");
				return;
			}
		}

		//Create the new dir
		if (!ensureDirExists (destPath)) {
			return;
		}

		//Unzip package's content
		unzipPackage (downloadedPackagePath, destPath);
	}

	private boolean ensureDirExists (String dir) {
		File file = new File (dir);
		boolean createDir = false;
		if (!file.exists ()) { //We have nothing at destination, so let's create a dir...
			createDir = true;
		} else if (!file.isDirectory ()) { //We have some file at place, so we have to delete it before creating the dir...
			if (!FileUtils.deleteRecursive (file.getAbsolutePath ())) {
				Log.e ("PackageManager", "ensureDirExists - Cannot remove file at path: " + dir);
				return false;
			}
			createDir = true;
		}

		if (createDir) {
			if (!file.mkdirs ()) {
				Log.e ("PackageManager", "ensureDirExists - Cannot create database at url: " + dir);
				return false;
			}
		}

		return true;
	}

	private String documentPath () {
		if (_overriddenDocURL != null) {
			return _overriddenDocURL;
		}

		return applicationContext.getFilesDir ().getAbsolutePath ();
	}

	private String databasePath () {
		String dbDir = null;
		if (_overriddenDatabaseURL != null) {
			dbDir = _overriddenDatabaseURL;
		} else {
			String docDir = applicationContext.getFilesDir ().getAbsolutePath ();
			dbDir = FileUtils.pathByAppendingPathComponent (docDir, "packages");
		}

		if (!ensureDirExists (dbDir)) {
			return null;
		}

		return dbDir;
	}

	private void movePackagesFromDocToDB (String docDir, String dbDir) {
		String[] enumerator = new File (docDir).list ();
		if (enumerator == null) {
			return;
		}

		for (String fileURL : enumerator) {
			File file = new File (FileUtils.pathByAppendingPathComponent (docDir, fileURL));
			if (file.isFile ()) {
				String ext = FileUtils.getPathExtension (fileURL);
				if (ext.toLowerCase ().equals ("apkg")) {
					String fileName = FileUtils.pathByDeletingPathExtension (file.getName ());
					String packageDir = FileUtils.pathByAppendingPathComponent (dbDir, fileName);
					if (ensureDirExists (packageDir)) {
						String fileDestURL = FileUtils.pathByAppendingPathComponent (packageDir, "package.apkg");

						FileUtils.deleteRecursive (fileDestURL);

						boolean resMove = FileUtils.moveTo (file.getAbsolutePath (), fileDestURL);
						if (!resMove) {
							Log.e ("PackageManager", "movePackagesFromDocToDB - Cannot move package to db at: " + fileURL);
						}
					}
				}
			}
		}
	}

	private String packageStateURL (String packURL) {
		return FileUtils.pathByAppendingPathComponent (packURL, "gamestate.json");
	}

	private native ArrayList<Package> extractLevel1Info (String dbDir);

	public ArrayList<Package> collectPackages () {
		String docDir = documentPath ();
		String dbDir = databasePath ();

		//Move packages from document dir to database
		movePackagesFromDocToDB (docDir, dbDir);

		//Extract package's level1 informations
		return extractLevel1Info (dbDir);
	}

	public void savePackageState (Package pack) {
		pack.state.saveTo (packageStateURL (pack.path));
	}
	//endregion

	//region Collecting saved crosswords of package
	private static class SWCNameComparator implements Comparator<SavedCrossword> {
		public int compare (SavedCrossword cw1, SavedCrossword cw2) {
			return cw1.name.compareTo (cw2.name);
		}
	}

	private native ArrayList<SavedCrossword> collectSavedCrosswordsOfPackage (String packageName, String packageDir);

	public HashMap<String, ArrayList<SavedCrossword>> collectSavedCrosswords () {
		String dbDir = databasePath ();

		//Enumerate packages in database and collect crosswords from it
		HashMap<String, ArrayList<SavedCrossword>> res = new HashMap<> ();
		for (String child : new File (dbDir).list ()) {
			File childFile = new File (FileUtils.pathByAppendingPathComponent (dbDir, child));
			if (childFile.isDirectory ()) {
				String packageName = child;
				ArrayList<SavedCrossword> packageCrosswords = collectSavedCrosswordsOfPackage (packageName, childFile.getAbsolutePath ());
				if (packageCrosswords != null && packageCrosswords.size () > 0) {
					Collections.sort (packageCrosswords, new SWCNameComparator ());
					res.put (packageName, packageCrosswords);
				}
			}
		}

		return res;
	}
	//endregion

	//region Collecting generation info
	private native int loadCardList (ArrayList<Deck> decks);

	public GeneratorInfo collectGeneratorInfo (ArrayList<Deck> decks) {
		//TODO: write the whole function in native!!!

		if (decks == null || decks.size ()  < 1) {
			return null;
		}

		//Collect most decks with same modelID (all of them have to be the same, but not guaranteed!)
		String packagePath = decks.get (0).pack.path;
		int cardListID = loadCardList (decks);

//		BOOL foundOneModelID = NO;
//		uint64_t maxCount = 0;
//		uint64_t choosenModelID = 0;
//		for (auto it : deckIndicesByModelID) {
//			if (it.second.size () > maxCount) {
//				choosenModelID = it.first;
//				maxCount = it.second.size ();
//				foundOneModelID = YES;
//			}
//		}
//
//		if (!foundOneModelID) {
//			return nil;
//		}
//
//		//Read used words of package
//		std::shared_ptr<UsedWords> usedWords = UsedWords::Create ([[packagePath path] UTF8String]);
//
		//Collect generator info
		GeneratorInfo info = new GeneratorInfo ();
//		info.splitArray = @[@";", @"\uff1b", @"<br", @"/>", @"<div>", @"</div>",
//			@"<span>", @"</span>", @"*", @"\r", @"\n", @",", @"\uff0c", @"(", @"\uff08", @")", @"\uff09",
//			@"[", @"\uff3b", @"]", @"\uff3d", @"{", @"\uff5b", @"}", @"\uff5d"];
//		info.solutionsFixes = [NSDictionary new];
//
//		auto itDeckIndices = deckIndicesByModelID.find (choosenModelID);
//		if (itDeckIndices == deckIndicesByModelID.end ()) {
//			return nil;
//		}
//
//		BOOL isFirstDeck = YES;
//		for (uint64_t deckIdx : itDeckIndices->second) {
//			std::shared_ptr<CardList> cardList = cardListsOfDecks[deckIdx];
//			if (cardList == nullptr) {
//				continue;
//			}
//
//			[[info decks] addObject:[decks objectAtIndex:deckIdx]];
//
//			if (isFirstDeck) { //Collect fields from first deck only
//				isFirstDeck = NO;
//
//				for (auto it : cardList->GetFields ()) {
//					Field *field = [[Field alloc] init];
//
//					[field setName:[NSString stringWithUTF8String:it.second->name.c_str ()]];
//					[field setIdx:it.second->idx];
//
//					[[info fields] addObject:field];
//				}
//			}
//
//			for (auto it : cardList->GetCards ()) {
//				Card *card = [[Card alloc] init];
//
//				[card setCardID:it.second->cardID];
//				[card setNoteID:it.second->noteID];
//				[card setModelID:it.second->modelID];
//
//				for (const std::string& fieldValue : it.second->fields) {
//					[[card fieldValues] addObject:[NSString stringWithUTF8String:fieldValue.c_str ()]];
//				}
//
//				[card setSolutionFieldValue:[NSString stringWithUTF8String:it.second->solutionField.c_str ()]];
//
//				[[info cards] addObject:card];
//			}
//		}
//
//		if (usedWords != nullptr) {
//			for (const std::wstring& word : usedWords->GetWords ()) {
//				NSUInteger len = word.length () * sizeof (wchar_t);
//				NSString *nsWord = [[NSString alloc] initWithBytes:word.c_str () length:len encoding:NSUTF32LittleEndianStringEncoding];
//				[info.usedWords addObject:nsWord];
//			}
//		}

		return info;
	}

	public void reloadUsedWords (String packagePath, GeneratorInfo info) {
	}
	//endregion

	//region Generate crossword based on info
	//-(NSString*)trimQuestionField:(NSString*)questionField;
	//-(NSString*)trimSolutionField:(NSString*)solutionField splitArr:(NSArray<NSString*>*)splitArr solutionFixes:(NSDictionary<NSString*, NSString*>*)solutionFixes;
	//-(BOOL)generateWithInfo:(GeneratorInfo*)info progressCallback:(void(^)(float, BOOL*))progressCallback;
	//endregion
}
