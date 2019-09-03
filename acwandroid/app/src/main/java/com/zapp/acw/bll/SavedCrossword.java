package com.zapp.acw.bll;

import android.util.Log;

import com.zapp.acw.FileUtils;

import java.io.File;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;
import java.util.TreeMap;

public final class SavedCrossword {
	private int nativeObjID = 0;

	public String path;
	public String packageName;
	public String name;

	public int width = 0;
	public int height = 0;
	public HashSet<String> words = new HashSet<> ();

	private static native void deleteUsedWordsFromDB (String packagePath, Set<String> words);
	private static native int loadDB (String path);
	private static native void unloadDB (int nativeObjID);

	private String filledValuesPath () {
		String pureFileName = FileUtils.pathByDeletingPathExtension (path);
		return FileUtils.pathByAppendingPathExtension (pureFileName, "filledValues");
	}

	public void eraseFromDisk () {
		//Delete used words from db
		if (words != null && words.size () > 0) {
			String packagePath = new File (path).getParent ();
			deleteUsedWordsFromDB (packagePath, words);
		}

		//Delete filled values
		String filledValuesPath = filledValuesPath ();
		if (!FileUtils.deleteRecursive (filledValuesPath)) {
			Log.e ("SavedCrossword", "Cannot delete crossword's filled values at path: " + filledValuesPath);
		}

		//Delete crossword
		if (!FileUtils.deleteRecursive (path)) {
			Log.e ("SavedCrossword","Cannot delete crossword at path: " + path);
		}
	}

	public void loadDB () {
		nativeObjID = loadDB (path);
	}

	public void unloadDB () {
		unloadDB (nativeObjID);
		nativeObjID = 0;
	}

	public void saveFilledValues (TreeMap<Pos, String> filledValues) {
		//Remove original file if exists
		String path = filledValuesPath ();

		if (new File (path).exists ()) {
			if (!FileUtils.deleteRecursive (path)) {
				//log...
				return;
			}
		}

		//Save filled values
		if (!FileUtils.writeObjectToPath (filledValues, path)) {
			//log...
			return;
		}
	}

	public void loadFilledValuesInto (TreeMap<Pos, String> filledValues) {
		//Clear original content
		filledValues.clear ();

		//Load content
		String path = filledValuesPath ();
		File file = new File (path);
		if (file.exists () && file.isFile ()) {
			TreeMap<Pos, String> dict = FileUtils.readObjectFromPath (path);
			Set<Pos> keySet = dict.keySet ();
			Iterator<Pos> it = keySet.iterator ();
			while (it.hasNext ()) {
				Pos key = it.next ();
				String value = dict.get (key);
				filledValues.put (key, value);
			}
		}
	}

//	-(NSArray<Statistics*>*) loadStatistics;
//	-(void) mergeStatistics:(uint32_t) failCount hintCount:(uint32_t)hintCount fillRatio:(double)fillRatio isFilled:(BOOL)isFilled fillDuration:(NSTimeInterval)fillDuration;
//	-(void) resetStatistics;
//
//	-(uint32_t) getCellTypeInRow:(uint32_t)row col:(uint32_t)col;
//	-(BOOL) isStartCell:(uint32_t)row col:(uint32_t)col;
//	-(NSString*) getCellsQuestion:(uint32_t)row col:(uint32_t)col questionIndex:(uint32_t)questionIndex;
//	-(NSString*) getCellsValue:(uint32_t)row col:(uint32_t)col;
//	-(uint32_t) getCellsSeparators:(uint32_t)row col:(uint32_t)col;
//
//	-(NSSet<NSString*>*) getUsedKeys;
}
