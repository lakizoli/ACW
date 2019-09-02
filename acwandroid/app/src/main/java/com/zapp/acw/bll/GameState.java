package com.zapp.acw.bll;

import android.util.JsonReader;
import android.util.JsonWriter;
import android.util.Log;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;

public final class GameState {
	public String crosswordName;
	public String overriddenPackageName;
	public int filledWordCount = 0;
	public int wordCount = 0;
	public int filledLevel = 0;
	public int levelCount = 0;

	public void loadFrom (String path) {
		JsonReader reader = null;
		InputStream inputStream = null;
		try {
			inputStream = new FileInputStream (path);
			reader = new JsonReader (new InputStreamReader (inputStream, "UTF-8"));

			reader.beginObject ();
			while (reader.hasNext ()) {
				switch (reader.nextName ()) {
					case "crosswordName":
						crosswordName = reader.nextString ();
						break;
					case "overriddenPackageName":
						overriddenPackageName = reader.nextString ();
						break;
					case "filledWordCount":
						filledWordCount = reader.nextInt ();
						break;
					case "wordCount":
						wordCount = reader.nextInt ();
						break;
					case "filledLevel":
						filledLevel = reader.nextInt ();
						break;
					case "levelCount":
						levelCount = reader.nextInt ();
						break;
					default:
						reader.skipValue ();
						break;
				}
			}
			reader.endObject ();
		} catch (Exception ex) {
			Log.e ("GameState", "loadFrom throws exception (1): " + ex);
		} finally {
			if (reader != null) {
				try {
					reader.close ();
				} catch (Exception ex) {
					Log.e ("GameState", "loadFrom throws exception (2): " + ex);
				}
			}

			if (inputStream != null) {
				try {
					inputStream.close ();
				} catch (Exception ex) {
					Log.e ("GameState", "loadFrom throws exception (3): " + ex);
				}
			}
		}
	}

	public void saveTo (String path) {
		JsonWriter writer = null;
		OutputStream outputStream = null;
		try {
			outputStream = new FileOutputStream (path);
			writer = new JsonWriter (new OutputStreamWriter (outputStream, "UTF-8"));
			writer.beginObject ();
			writer.name ("crosswordName").value (crosswordName);
			writer.name ("overriddenPackageName").value (overriddenPackageName);
			writer.name ("filledWordCount").value (filledWordCount);
			writer.name ("wordCount").value (wordCount);
			writer.name ("filledLevel").value (filledLevel);
			writer.name ("levelCount").value (levelCount);
			writer.endObject ();
		} catch (Exception ex) {
			Log.e ("GameState", "saveTo throws exception (1): " + ex);
		} finally {
			if (writer != null) {
				try {
					writer.close ();
				} catch (Exception ex) {
					Log.e ("GameState", "saveTo throws exception (2): " + ex);
				}
			}

			if (outputStream != null) {
				try {
					outputStream.close ();
				} catch (Exception ex) {
					Log.e ("GameState", "saveTo throws exception (3): " + ex);
				}
			}
		}
	}
}