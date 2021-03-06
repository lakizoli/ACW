package com.zapp.acw.ui.main;

import android.app.Activity;
import android.util.Pair;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.zapp.acw.FileUtils;
import com.zapp.acw.bll.Deck;
import com.zapp.acw.bll.Downloader;
import com.zapp.acw.bll.NetLogger;
import com.zapp.acw.bll.NetPackConfig;
import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.PackageManager;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;

public class DownloadViewModel extends ViewModel {
	private final static String NETPACK_CFG_ID = "1DRdHyx9Pj6XtdPrKlpBmGo4BMz9ecbUR";

	public final static int DISMISS_VIEW = 1;
	public final static int SHOW_FAILED_ALERT = 2;
	public final static int SHOW_GEN_VIEW = 3;

	public final static int TAB_FEATURED = 0;
	public final static int TAB_SEARCH = 1;

	private MutableLiveData<Integer> _action = new MutableLiveData<> ();
	private Downloader _downloader = null;
	private MutableLiveData<ArrayList<NetPackConfig.NetPackConfigItem>> _packageConfigs = new MutableLiveData<> ();
	private MutableLiveData<Pair<Integer, String>> _progress = new MutableLiveData<> ();
	private int _lastProgress = -1;
	private Package _package = null;

	public MutableLiveData<Integer> getAction () {
		return _action;
	}
	public MutableLiveData<ArrayList<NetPackConfig.NetPackConfigItem>> getPackageConfigs () {
		return _packageConfigs;
	}
	public MutableLiveData<Pair<Integer, String>> getProgress () {
		return _progress;
	}
	public Package getPackage () {
		return _package;
	}

	public int selectedTab = TAB_FEATURED;

	private void endOfDownload (final Activity activity, final boolean showFailedAlert, final String downloadedFile, final boolean doGen, final String packageNameFull) {
		activity.runOnUiThread (new Runnable () {
			@Override
			public void run () {
				if (showFailedAlert) {
					if (downloadedFile != null && downloadedFile.length () > 0) {
						FileUtils.deleteRecursive (downloadedFile);
					}

					_action.postValue (SHOW_FAILED_ALERT);
				} else {
					if (doGen) {
						String packageName = packageNameFull;
						String ext = FileUtils.getPathExtension (packageNameFull);
						if (ext.length () > 0) {
							packageName = packageNameFull.substring (0, packageNameFull.length () - ext.length () - 1);
						}

						ArrayList<Package> packages = PackageManager.sharedInstance ().collectPackages ();
						for (int i = 0, iEnd = packages.size (); i < iEnd; ++i) {
							Package pack = packages.get (i);
							String testPackageName = FileUtils.getFileName (pack.path);
							if (testPackageName.equals (packageName)) {
								_package = pack;
								break;
							}
						}

						if (_package != null && _package.decks != null && _package.decks.size () > 0) {
							_action.postValue (SHOW_GEN_VIEW);
						} else {
							_action.postValue (DISMISS_VIEW);
						}
					} else {
						_action.postValue (DISMISS_VIEW);
					}
				}
			}
		});
	}

	public void cancelDownload () {
		if (_downloader != null) {
			_downloader.cancel ();
		}
	}

	private void updateProgress (long pos, long size) {
		String progress = Downloader.createDataProgressLabel (pos, size);
		String label = String.format ("%s", progress);

		if (size > 0) {
			int percent = (int) ((float)pos / (float)size * 100.0f);
			if (percent != _lastProgress) {
				_lastProgress = percent;
				_progress.postValue (new Pair<Integer, String> (percent, label));
			}
		}
	}

	//region Google downloader functions
	@FunctionalInterface
	public interface ContentHandler {
		void apply (String downloadedFile, String fileName);
	}

	private String getDownloadLinkForGoogleDrive (String fileID) {
		return String.format ("https://drive.google.com/uc?id=%s&export=download", fileID);
	}

	private String getURLForMovedContentOnGoogleDrive (String filePath) {
		long fileSize = new File (filePath).length ();
		if (fileSize >= 10000) { //If file is too big, then cannot be moving desc
			return null;
		}

		String content = FileUtils.readFile (filePath);
		if (content != null && content.length () > 0) {
			String contentLower = content.toLowerCase ();
			int range = contentLower.indexOf ("<head>");
			if (range >= 0) {
				range = content.indexOf ("Moved");
				if (range >= 0) {
					range = contentLower.indexOf ("href");
					if (range >= 0) {
						content = content.substring (range + 4); //length of "href" == 4
						range = content.indexOf ("\"");
						if (range >= 0) {
							content = content.substring (0, range);
							return content;
						}
					}
				}
			}
		}

		return null;
	}

	private String getURLForConfirmedContentOnGoogleDrive (String filePath, String origURL) {
		long fileSize = new File (filePath).length ();
		if (fileSize >= 10000) { //If file is too big, then cannot be moving desc
			return null;
		}

		String content = FileUtils.readFile (filePath);
		if (content != null && content.length () > 0) {
			String contentLower = content.toLowerCase ();
			int range = contentLower.indexOf ("<head>");
			if (range >= 0) {
				String search = "export=download&amp;confirm=";
				range = contentLower.indexOf (search);
				if (range >= 0) {
					content = content.substring (range + search.length ());
					range = content.indexOf ("&amp;");
					if (range >= 0) {
						content = content.substring (0, range);
						return origURL + String.format ("&confirm=%s", content);
					}
				}
			}
		}

		return null;
	}

	private void downloadFileFromGoogleDrive (final Activity activity, final String url, final boolean handleEnd,
											  final ContentHandler contentHandler, final Downloader.DownloaderProgressHandler progressHandler) {
		if (_downloader != null) {
			_downloader.cancel ();
		}

		_downloader = Downloader.downloadFile (activity, url, progressHandler, new Downloader.DownloaderCompletionHandler () {
			@Override
			public void apply (Downloader.DownloadResult resultCode, String downloadedFile, String fileName) {
				boolean showFailedAlert = false;
				switch (resultCode) {
					case DownloadResult_Succeeded: {
						String movedContentURL = getURLForMovedContentOnGoogleDrive (downloadedFile);
						if (movedContentURL != null && movedContentURL.length () > 0) { //Moved content on the Google Drive
							downloadFileFromGoogleDrive (activity, movedContentURL, handleEnd, contentHandler, progressHandler);
							return;
						}

						String confirmURL = getURLForConfirmedContentOnGoogleDrive (downloadedFile, url);
						if (confirmURL != null && confirmURL.length () > 0) {
							downloadFileFromGoogleDrive (activity, confirmURL, handleEnd, contentHandler, progressHandler);
							return;
						}

						//Full file downloaded
						if (contentHandler != null) {
							contentHandler.apply (downloadedFile, fileName);
						}
						break;
					}
					case DownloadResult_Failed:
						showFailedAlert = true;
						NetLogger.logEvent ("Obtain_NetPackage_Failed", new HashMap<String, String> () {{
							put ("url", url);
						}});
						break;
					case DownloadResult_Cancelled:
						NetLogger.logEvent ("Obtain_NetPackage_Cancelled", new HashMap<String, String> () {{
							put ("url", url);
						}});
						break;
					default:
						NetLogger.logEvent ("Obtain_NetPackage_Unknown", new HashMap<String, String> () {{
							put ("url", url);
						}});
						break;
				}

				if (handleEnd) {
					endOfDownload (activity, showFailedAlert, downloadedFile, false, null);
				}
			}
		});
	}

	public void startDownloadPackageList (final Activity activity) {
		String packUrl = getDownloadLinkForGoogleDrive (NETPACK_CFG_ID);
		downloadFileFromGoogleDrive (activity, packUrl, false, new ContentHandler () {
			@Override
			public void apply (String downloadedFile, String fileName) {
				NetPackConfig netPackConfig = NetPackConfig.parse (downloadedFile);

				final ArrayList<NetPackConfig.NetPackConfigItem> packageConfigs = new ArrayList<> ();

				netPackConfig.enumerateLanguagesWihtBlock (new NetPackConfig.ConfigEnumerator () {
					@Override
					public void apply (NetPackConfig.NetPackConfigItem item) {
						packageConfigs.add (item);
					}
				});

				_packageConfigs.postValue (packageConfigs);
			}
		}, null);
	}
	//endregion

	//region Download net package from the Google
	public void startDownloadPackage (final Activity activity, final NetPackConfig.NetPackConfigItem configItem) {
		final String url = getDownloadLinkForGoogleDrive (configItem.fileID);

		NetLogger.logEvent ("Obtain_NetPackage_Selected", new HashMap<String, String> () {{
			put ("label", configItem.label);
			put ("url", url);
		}});

		_lastProgress = -1;

		downloadFileFromGoogleDrive (activity, url, true, new ContentHandler () {
			@Override
			public void apply (final String downloadedFile, final String fileName) {
				NetLogger.logEvent ("Obtain_NetPackage_Downloaded", new HashMap<String, String> () {{
					put ("label", configItem.label);
					put ("url", downloadedFile);
					put ("fileName", fileName);
				}});

				//Unzip downloaded file to packages
				PackageManager.sharedInstance ().unzipDownloadedPackage (downloadedFile, FileUtils.pathByDeletingPathExtension (fileName));
			}
		}, new Downloader.DownloaderProgressHandler () {
			@Override
			public void apply (long pos, long size) {
				if (size <= 0) {
					size = configItem.size;
				}

				updateProgress (pos, size);
			}
		});
	}
	//endregion

	//region Anki package download
	public void startDownloadOfAnkiPackage (final Activity activity, final String url, final boolean doGenerationAfterDownload) {
		NetLogger.logEvent ("Obtain_AnkiPackage_Selected", new HashMap<String, String> () {{
			put ("url", url);
		}});

		_downloader = Downloader.downloadFile (activity, url, new Downloader.DownloaderProgressHandler () {
			@Override
			public void apply (long pos, long size) {
				updateProgress (pos, size);
			}
		}, new Downloader.DownloaderCompletionHandler () {
			@Override
			public void apply (final Downloader.DownloadResult resultCode, String downloadedFile, final String fileName) {
				NetLogger.logEvent ("Obtain_AnkiPackage_Downloaded", new HashMap<String, String> () {{
					put ("url", url);
					put ("fileName", fileName.length () > 0 ? fileName : "null");
					put ("resultCode", resultCode.toString ());
				}});

				String destFileName = null;
				boolean doGen = false;
				boolean showFailedAlert = false;
				switch (resultCode) {
					case DownloadResult_Succeeded: {
						String docDir = activity.getFilesDir ().getAbsolutePath ();
						if (fileName != null && fileName.length () > 0 && !fileName.equals ("unknown")) {
							destFileName = fileName;
						} else {
							destFileName = FileUtils.pathByAppendingPathExtension (FileUtils.getFileName (downloadedFile), "apkg");
						}
						String destDir = FileUtils.pathByAppendingPathComponent (docDir, destFileName);
						FileUtils.deleteRecursive (destDir);
						if (!FileUtils.moveTo (downloadedFile, destDir)) { //Failed move
							showFailedAlert = true;
						} else { //Succeeded move
							doGen = doGenerationAfterDownload;
						}
						break;
					}
					case DownloadResult_Failed:
						showFailedAlert = true;
						NetLogger.logEvent ("Obtain_AnkiPackage_Failed", new HashMap<String, String> () {{
							put ("url", url);
						}});
						break;
					case DownloadResult_Cancelled:
						NetLogger.logEvent ("Obtain_AnkiPackage_Cancelled", new HashMap<String, String> () {{
							put ("url", url);
						}});
						break;
					default:
						NetLogger.logEvent ("Obtain_AnkiPackage_Unknown", new HashMap<String, String> () {{
							put ("url", url);
						}});
						break;
				}

				endOfDownload (activity, showFailedAlert, downloadedFile, doGen, destFileName);
			}
		});
	}
	//endregion
}
