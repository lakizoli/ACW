package com.zapp.acw.bll;

import android.os.Parcel;
import android.os.Parcelable;
import android.util.Log;

import com.zapp.acw.FileUtils;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.HashMap;

import androidx.annotation.Keep;

@Keep
public final class SavedCrossword implements Parcelable {
	private int nativeObjID = 0;

	public String path;
	public String packageName;
	public String name;

	public int width = 0;
	public int height = 0;
	public HashSet<String> words = new HashSet<> ();

	public SavedCrossword () {
	}

	//region Parcelable implementation
	public static final Parcelable.Creator<SavedCrossword> CREATOR = new Parcelable.Creator<SavedCrossword> () {
		public SavedCrossword createFromParcel (Parcel source) {
			return new SavedCrossword (source);
		}

		public SavedCrossword[] newArray (int size) {
			return new SavedCrossword[size];
		}
	};

	public SavedCrossword (Parcel parcel) {
		nativeObjID = parcel.readInt ();

		path = parcel.readString ();
		packageName = parcel.readString ();
		name = parcel.readString ();

		width = parcel.readInt ();
		height = parcel.readInt ();

		List<String> list = new ArrayList<> ();
		parcel.readStringList (list);
		if (list != null && list.size () > 0) {
			words = new HashSet<> (list);
		}
	}

	@Override
	public int describeContents () {
		return hashCode ();
	}

	@Override
	public void writeToParcel (Parcel dest, int flags) {
		dest.writeInt (nativeObjID);

		dest.writeString (path);
		dest.writeString (packageName);
		dest.writeString (name);

		dest.writeInt (width);
		dest.writeInt (height);
		if (words != null && words.size () > 0) {
			dest.writeStringList (new ArrayList<> (words));
		} else {
			dest.writeStringList (null);
		}
	}
	//endregion

	//region DB functions
	private static native void deleteUsedWordsFromDB (String packagePath, Set<String> words);
	private static native int loadDB (String path);
	private static native void unloadDB (int nativeObjID);

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
	//endregion

	//region Filled Values
	private String filledValuesPath () {
		String pureFileName = FileUtils.pathByDeletingPathExtension (path);
		return FileUtils.pathByAppendingPathExtension (pureFileName, "filledValues");
	}

	public void saveFilledValues (HashMap<Pos, String> filledValues) {
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

	public void loadFilledValuesInto (HashMap<Pos, String> filledValues) {
		//Clear original content
		filledValues.clear ();

		//Load content
		String path = filledValuesPath ();
		File file = new File (path);
		if (file.exists () && file.isFile ()) {
			HashMap<Pos, String> dict = FileUtils.readObjectFromPath (path);
			Set<Pos> keySet = dict.keySet ();
			Iterator<Pos> it = keySet.iterator ();
			while (it.hasNext ()) {
				Pos key = it.next ();
				String value = dict.get (key);
				filledValues.put (key, value);
			}
		}
	}
	//endregion

	//region Statistics
	private String statisticsOffsetPath () {
		String pureFileName = FileUtils.pathByDeletingPathExtension (path);
		return FileUtils.pathByAppendingPathExtension (pureFileName, "statisticsOffset");
	}

	public void saveStatisticsOffset (int offset) {
		String path = statisticsOffsetPath ();
		if (new File (path).exists ()) {
			if (!FileUtils.deleteRecursive (path)) {
				//log...
				return;
			}
		}

		String content = Integer.toString (offset);
		if (!FileUtils.writeObjectToPath (content, path)) {
			//log...
			return;
		}
	}

	public int loadStatisticsOffset () {
		String path = statisticsOffsetPath ();
		if (new File (path).exists ()) {
			String content = FileUtils.readObjectFromPath (path);
			if (content != null) {
				return Integer.parseInt (content);
			}
		}

		return -1; //file not found
	}

	private String statisticsPath () {
		String pureFileName = FileUtils.pathByDeletingPathExtension (path);
		return FileUtils.pathByAppendingPathExtension (pureFileName, "statistics");
	}

	private Statistics getCurrentStatistics (ArrayList<Statistics> statistics) {
		Statistics currentStat = null;
		if (statistics.size () > 0) {
			Statistics stat = statistics.get (statistics.size () - 1);
			if (!stat.isFilled) {
				currentStat = stat;
			}
		}

		if (currentStat == null) {
			currentStat = new Statistics ();
			statistics.add (currentStat);
		}

		return currentStat;
	}

	private void saveStatistics (ArrayList<Statistics> stats) {
		//Remove original file if exists
		String path = statisticsPath ();

		if (new File (path).exists ()) {
			if (!FileUtils.deleteRecursive (path)) {
				//log...
				return;
			}
		}

		//Save filled values
		if (!FileUtils.writeObjectToPath (stats, path)) {
			//log...
			return;
		}
	}

	public ArrayList<Statistics> loadStatistics () {
		ArrayList<Statistics> stats = new ArrayList<> ();

		//Load content
		String path = statisticsPath ();
		File file = new File (path);
		if (file.exists () && file.isFile ()) {
			stats = FileUtils.readObjectFromPath (path);
		}

		return stats;
	}

	public void mergeStatistics (int failCount, int hintCount, double fillRatio, boolean isFilled, int fillDuration) {
		//Obtain current statistic
		ArrayList<Statistics> stats = loadStatistics ();
		Statistics currentStat = getCurrentStatistics (stats);

		//Merge values to the current statistic
		currentStat.failCount += failCount;
		currentStat.hintCount += hintCount;
		currentStat.fillRatio = fillRatio;
		currentStat.fillDuration += fillDuration;
		currentStat.isFilled = isFilled;

		//Save statistics
		saveStatistics (stats);
	}

	public void resetStatistics () {
		//Obtain current statistic
		ArrayList<Statistics> stats = loadStatistics ();
		Statistics currentStat = getCurrentStatistics (stats);

		//Reset current statistics
		currentStat.failCount = 0;
		currentStat.hintCount = 0;
		currentStat.fillRatio = 0.0;
		currentStat.fillDuration = 0;
		currentStat.isFilled = false;

		//Save statistics
		saveStatistics (stats);
	}
	//endregion

	//region Cell functions
	public native int getCellTypeInRow (int row, int col);
	public native boolean isStartCell (int row, int col);
	public native String getCellsQuestion (int row, int col, int questionIndex);
	public native String getCellsValue (int row, int col);
	public native int getCellsSeparators (int row, int col);
	//endregion

	public native HashSet<String> getUsedKeys ();
}
