package com.zapp.acw.bll;

import android.content.Context;
import android.util.Log;

import com.zapp.acw.FileUtils;

import java.io.File;
import java.util.ArrayList;

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



//-(NSDictionary<NSString*, NSArray<SavedCrossword*>*>*)collectSavedCrosswords;
//-(GeneratorInfo*)collectGeneratorInfo:(NSArray<Deck*>*)decks;
//-(void)reloadUsedWords:(NSURL*)packagePath info:(GeneratorInfo*)info;
//
//-(NSString*)trimQuestionField:(NSString*)questionField;
//-(NSString*)trimSolutionField:(NSString*)solutionField splitArr:(NSArray<NSString*>*)splitArr solutionFixes:(NSDictionary<NSString*, NSString*>*)solutionFixes;
//-(BOOL)generateWithInfo:(GeneratorInfo*)info progressCallback:(void(^)(float, BOOL*))progressCallback;

}
