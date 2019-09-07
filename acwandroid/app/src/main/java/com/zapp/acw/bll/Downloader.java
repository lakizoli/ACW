package com.zapp.acw.bll;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public final class Downloader {
	private Context _context;
	private String _url;
	private DownloaderProgressHandler _progressHandler;
	private DownloaderCompletionHandler _completionHandler;
	private String _fileName;
	private long _contentLength = 0;
	private boolean _cancelled = false;

	private Downloader () {
	}

	public enum DownloadResult {
		DownloadResult_Failed,
		DownloadResult_Cancelled,
		DownloadResult_Succeeded
	}

	@FunctionalInterface
	public interface DownloaderProgressHandler {
		void apply (long pos, long size);
	}

	@FunctionalInterface
	public interface DownloaderCompletionHandler {
		void apply (DownloadResult resultCode, String downloadedFile, String fileName);
	}

	public static Downloader downloadFile (Context context, final String url, DownloaderProgressHandler progressHandler, DownloaderCompletionHandler completionHandler) {
		final Downloader downloader = new Downloader ();
		downloader._context = context;
		downloader._url = url;
		downloader._progressHandler = progressHandler;
		downloader._completionHandler = completionHandler;
		downloader._fileName = "unknown";
		downloader._contentLength = 0;
		downloader._cancelled = false;

		new Thread (new Runnable () {
			@Override
			public void run () {
				String outputPath = null;
				BufferedInputStream reader = null;
				BufferedOutputStream writer = null;
				try {
					URL regUrl = new URL (downloader._url);
					HttpURLConnection conn = (HttpURLConnection) regUrl.openConnection ();
					downloader._contentLength = conn.getContentLength ();
					downloader._fileName = parseFileName (conn);

					File outputDir = downloader._context.getCacheDir ();
					File outputFile = new File (outputDir, downloader._fileName);
					if (outputFile.exists ()) {
						outputFile.delete ();
					}

					outputFile.createNewFile ();
					outputPath = outputFile.getAbsolutePath ();

					InputStream inputStream = conn.getInputStream ();
					reader = new BufferedInputStream (inputStream);

					writer = new BufferedOutputStream (new FileOutputStream (outputFile.getAbsoluteFile ()));

					byte[] buffer = new byte[4096];
					long bytesWritten = 0;
					int bytesRead = -1;

					while ((bytesRead = reader.read (buffer)) != -1 && !downloader._cancelled) {
						writer.write (buffer, 0, bytesRead);
						bytesWritten += bytesRead;

						if (downloader._progressHandler != null) {
							downloader._progressHandler.apply (bytesWritten, downloader._contentLength);
						}
					}

					writer.close ();
					writer = null;

					reader.close ();
					reader = null;

					DownloadResult resCode = downloader._cancelled ? DownloadResult.DownloadResult_Cancelled : DownloadResult.DownloadResult_Succeeded;
					downloader._completionHandler.apply (resCode, outputFile.getAbsolutePath (), downloader._fileName);
				} catch (Exception ex) {
					Log.e ("Downloader", "downloadFile - exception (1): " + ex);
					downloader._completionHandler.apply (DownloadResult.DownloadResult_Failed, outputPath, downloader._fileName);
				} finally {
					try {
						if (writer != null) {
							writer.close ();
						}
					} catch (Exception ex) {
						Log.e ("Downloader", "downloadFile - exception (2): " + ex);
					}

					try {
						if (reader != null) {
							reader.close ();
						}
					} catch (Exception ex) {
						Log.e ("Downloader", "downloadFile - exception (3): " + ex);
					}
				}
			}
		}).start ();

		return downloader;
	}

	@SuppressLint("DefaultLocale")
	public static String createDataProgressLabel (long pos, long size) {
		String posItem;
		float posAmount = 0;
		if (pos >= 1024 * 1024 * 1024) { //GB
			posItem = "GB";
			posAmount = pos / 1024.0f / 1024.0f / 1024.0f;
		} else if (pos >= 1024 * 1024) { //MB
			posItem = "MB";
			posAmount = pos / 1024.0f / 1024.0f;
		} else if (pos >= 1024) { //KB
			posItem = "KB";
			posAmount = pos / 1024.0f;
		} else { //B
			posItem = "B";
			posAmount = pos;
		}

		String sizeItem;
		float sizeAmount = 0;
		if (size >= 1024 * 1024 * 1024) { //GB
			sizeItem = "GB";
			sizeAmount = size / 1024.0f / 1024.0f / 1024.0f;
		} else if (size >= 1024 * 1024) { //MB
			sizeItem = "MB";
			sizeAmount = size / 1024.0f / 1024.0f;
		} else if (size >= 1024) { //KB
			sizeItem = "KB";
			sizeAmount = size / 1024.0f;
		} else { //B
			sizeItem = "B";
			sizeAmount = size;
		}

		return String.format ("%.2f%s / %.2f%s", posAmount, posItem, sizeAmount, sizeItem);
	}

	public void cancel () {
		_cancelled = true;
	}

	private static String parseFileName (HttpURLConnection conn) {
		String fileName = "unknown";
		String raw = conn.getHeaderField ("Content-Disposition"); // raw = "attachment; filename=abc.jpg"
		if (raw != null && raw.length () > 0) {
			String[] items = raw.split (";");
			if (items != null && items.length > 0) {
				for (String item : items) {
					if (item.startsWith ("filename=")) {
						fileName = item.substring (9).replaceAll ("\"", " ").trim ();
					}
				}
			}
		}
		return fileName;
	}
}
