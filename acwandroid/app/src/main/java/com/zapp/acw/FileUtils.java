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

	public static boolean deleteRecursive (String path) {
		File file = new File (path);
		if (!file.exists ()) {
			return true;
		}

		//Delete recursively
		ArrayDeque<String> queue = new ArrayDeque<> ();
		queue.addLast (file.getAbsolutePath ());

		while (queue.size () > 0) {
			String itemPath = queue.pollFirst ();

			File item = new File (itemPath);
			if (item.isDirectory ()) {
				String[] children = item.list ();
				if (children != null && children.length > 0) {
					queue.addFirst (itemPath);
					for (String child : children) {
						queue.addFirst (itemPath + "/" + child);
					}
					continue;
				}
			}

			//delete file or empty directory
			if (!item.delete ()) {
				return false;
			}
		}

		return true;
	}
}
