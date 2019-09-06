package com.zapp.acw.ui.main;

import android.app.Activity;

import com.zapp.acw.bll.Downloader;

import androidx.lifecycle.ViewModel;

public class DownloadViewModel extends ViewModel {
	Downloader _downloader;

	@FunctionalInterface
	public interface ContentHandler {
		void apply (String url, String fileName);
	}

	private void downloadFileFromGoogleDrive (final Activity activity, String url, boolean handleEnd, ContentHandler contentHandler, Downloader.DownloaderProgressHandler progressHandler) {
		if (_downloader != null) {
			_downloader.cancel ();
		}

		//TODO: ...
		_downloader = Downloader.downloadFile (activity, url, progressHandler, new Downloader.DownloaderCompletionHandler () {
			@Override
			public void apply (Downloader.DownloadResult resultCode, String downloadedFile, String fileName) {
			}
		});
	}

	public void startDownoadPackageList (final Activity activity) {
	}
}
