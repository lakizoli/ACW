package com.zapp.acw.bll;

import android.content.Context;
import android.util.Log;

import com.zapp.acw.FileUtils;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;
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
	public native GeneratorInfo collectGeneratorInfo (ArrayList<Deck> decks);
	public native void reloadUsedWords (String packagePath, GeneratorInfo info);
	//endregion

	//region Generate crossword based on info
	private String trimStart (String str) {
		int index;
		for (index = 0; index < str.length(); index++) {
			if (!Character.isWhitespace (str.charAt(index))) {
				break;
			}
		}
		return str.substring(index);
	}

	private String trimEnd (String str) {
		int index;
		for (index = str.length() - 1; index >= 0; index--) {
			if (!Character.isWhitespace (str.charAt(index))) {
				break;
			}
		}
		return str.substring(0, index + 1);
	}

	private static String _fixRegexChars = "*(){}[]";
	private String fixRegex (String pattern) {
		if (_fixRegexChars.contains (pattern)) {
			return "\\" + pattern;
		}

		return pattern;
	}

	private String parseXml (XmlPullParser parser) throws IOException, XmlPullParserException {
		String value = "";

		boolean firstValueRead = false;
		boolean quit = false;
		int eventType = parser.getEventType ();
		while (!quit && eventType != XmlPullParser.END_DOCUMENT) {
			switch (eventType) {
				case XmlPullParser.START_TAG:
					if (!firstValueRead) {
						value = parser.nextText ();
						firstValueRead = true;
					}
					break;
				case XmlPullParser.END_TAG:
					if (firstValueRead) {
						quit = true;
					}
					break;
				default:
					break;
			}

			eventType = parser.next ();
		}
		return value;
	}

	public String trimQuestionField (String questionField) {
		String field = trimStart (trimEnd (questionField));

		//Try to detect HTML content
		if (field.startsWith ("<")) {
			try {
				XmlPullParserFactory parserFactory = XmlPullParserFactory.newInstance ();
				XmlPullParser parser = parserFactory.newPullParser ();
				StringReader reader = new StringReader (field);
				parser.setInput (reader);
				field = parseXml (parser);
			} catch (Exception ex) {
				Log.e ("PackageManager", "trimQuestionField, parseXml - ex: " + ex.toString ());
				return null;
			}
		}

		//Convert separators to usable format
		field = field.replaceAll ("&nbsp;", " ");

		ArrayList<String> separatorArr = new ArrayList<String> () {{
			add (";"); add ("<br"); add ("/>"); add ("<div>"); add ("</div>"); add ("*"); add ("\r"); add ("\n");
		}};
		for (String separatorStr : separatorArr) {
			separatorStr = fixRegex (separatorStr);
			field = field.replaceAll (separatorStr, ":");
			field = field.replaceAll ("  ", " ");
			field = field.replaceAll (": :", ", ");
			field = field.replaceAll ("::", ", ");
		}

		field = field.replaceAll (":", ", ");
		while (field.endsWith (", ")) {
			field = field.substring (0, field.length () - 2);
		}

//		Log.d ("PackageManager", questionField + " -> " + field);
		return field;
	}

	public String trimSolutionField (String solutionField, ArrayList<String> splitArr, HashMap<String, String> solutionFixes) {
		String fixedSolution = solutionFixes.get (solutionField);
		if (fixedSolution != null) {
			return fixedSolution;
		}

		String field = trimStart (trimEnd (solutionField));

		//Try to detect HTML content
		if (field.startsWith ("<")) {
			try {
				XmlPullParserFactory parserFactory = XmlPullParserFactory.newInstance ();
				XmlPullParser parser = parserFactory.newPullParser ();
				StringReader reader = new StringReader (field);
				parser.setInput (reader);
				field = parseXml (parser);
			} catch (Exception ex) {
				Log.e ("PackageManager", "trimSolutionField, parseXml - ex: " + ex.toString ());
				return null;
			}
		}

		//Replace chars in word
		HashMap<String, String> replacePairs = new HashMap<String, String> () {{
			put ("&nbsp;", " ");
			put ("  ", " ");
		}};
		for (Map.Entry<String, String> entry : replacePairs.entrySet ()) {
			field = field.replaceAll (entry.getKey (), entry.getValue ());
		}

		//Pull word out from garbage
		for (String splitStr : splitArr) {
			splitStr = fixRegex (splitStr);
			String trimmed = trimStart (trimEnd (field));
			String[] items = trimmed.split (splitStr);
			if (items != null && items.length > 0) {
				field = items[0];
			} else {
				field = trimmed;
			}
		}

//		Log.d ("PackageManager", solutionField + " -> " + field);
		return field;
	}

	public interface ProgressCallback {
		boolean apply (float progress);
	}

	public native boolean generateWithInfo (GeneratorInfo info, ProgressCallback progressCallback);
	//endregion
}
