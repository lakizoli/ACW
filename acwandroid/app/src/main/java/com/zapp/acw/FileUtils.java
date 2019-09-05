package com.zapp.acw;

import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.util.ArrayDeque;

public final class FileUtils {
	public static String pathByDeletingLastPathComponent (String path) {
		return new File (path).getParent ();
	}

	public static String pathByAppendingPathComponent (String path, String component) {
		return new File (path, component).getAbsolutePath ();
	}

	public static String pathByDeletingPathExtension (String path) {
		File file = new File (path);
		String packageDir = file.getParent ();
		String name = file.getName ();
		int posDot = name.lastIndexOf ('.');
		String pureFileName = posDot < 0 ? name : name.substring (0,  posDot);
		if (packageDir == null || (packageDir != null && packageDir.length () <= 0)) {
			return pureFileName;
		}
		return new File (packageDir, pureFileName).getAbsolutePath ();
	}

	public static String pathByAppendingPathExtension (String path, String ext) {
		return path + "." + ext;
	}

	public static String getPathExtension (String path) {
		File file = new File (path);
		String name = file.getName ();
		int posDot = name.lastIndexOf ('.');
		return posDot < 0 ? "" : (name.length () <= posDot + 1 ? "" : name.substring (posDot + 1));
	}

	public static <T> T readObjectFromPath (String path) {
		FileInputStream is = null;
		ObjectInputStream ois = null;
		try {
			is = new FileInputStream (path);
			ois = new ObjectInputStream (is);

			@SuppressWarnings ("unchecked")
			T res = (T) ois.readObject ();

			return res;
		} catch (Exception ex) {
			Log.e ("FileUtils", "readObjectFromPath exception (1): " + ex);
		} finally {
			try {
				if (ois != null) {
					ois.close ();
				}
			} catch (Exception ex) {
				Log.e ("FileUtils", "readObjectFromPath exception (2): " + ex);
			}

			try {
				if (is != null) {
					is.close ();
				}
			} catch (Exception ex) {
				Log.e ("FileUtils", "readObjectFromPath exception (3): " + ex);
			}
		}

		return null;
	}

	public static boolean writeObjectToPath (Serializable obj, String path) {
		FileOutputStream os = null;
		ObjectOutputStream oos = null;
		try {
			os = new FileOutputStream (path);
			oos = new ObjectOutputStream (os);
			oos.writeObject (obj);
			return true;
		} catch (Exception ex) {
			Log.e ("FileUtils", "writeObjectToPath exception (1): " + ex);
		} finally {
			try {
				if (oos != null) {
					oos.close ();
				}
			} catch (Exception ex) {
				Log.e ("FileUtils", "writeObjectToPath exception (2): " + ex);
			}

			try {
				if (os != null) {
					os.close ();
				}
			} catch (Exception ex) {
				Log.e ("FileUtils", "writeObjectToPath exception (3): " + ex);
			}
		}

		return false;
	}

	public static native boolean deleteRecursive (String path);
	public static native boolean copyRecursive (String sourcePath, String destPath);
	public static native boolean moveTo (String sourcePath, String destPath);
}
