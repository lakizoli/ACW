package com.zapp.acw;

import java.io.File;
import java.io.Serializable;

public final class FileUtils {
	public static String pathByDeletingLastPathComponent (String path) {
		return new File (path).getParent ();
	}

	public static String pathByDeletingPathExtension (String path) {
		File cwFile = new File (path);
		String packageDir = cwFile.getParent ();
		String cwName = cwFile.getName ();
		int posDot = cwName.lastIndexOf ('.');
		String pureFileName = posDot < 0 ? cwName : cwName.substring (0,  posDot);
		return new File (packageDir, pureFileName).getAbsolutePath ();
	}

	public static String pathByAppendingPathExtension (String path, String ext) {
		return path + "." + ext;
	}

	public static <T> T readObjectFromPath (String path) {
		//TODO: implement
		return null;
	}

	public static boolean writeObjectToPath (Serializable obj, String path) {
		//TODO: implement
		return false;
	}

	public static boolean deleteRecursive (String path) {
		//TODO: implement
		return false;
	}
}
