package com.zapp.acw.ui.main;

import android.app.Activity;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.zapp.acw.FileUtils;
import com.zapp.acw.bll.Downloader;
import com.zapp.acw.bll.NetLogger;
import com.zapp.acw.bll.NetPackConfig;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;

public class DownloadViewModel extends ViewModel {
	private final static String NETPACK_CFG_ID = "1DRdHyx9Pj6XtdPrKlpBmGo4BMz9ecbUR";

	public final static int DISMISS_VIEW = 1;
	public final static int SHOW_FAILED_ALERT = 2;
	public final static int SHOW_GEN_VIEW = 3;

	private MutableLiveData<Integer> _action = new MutableLiveData<> ();
	private Downloader _downloader = null;
	private MutableLiveData<ArrayList<NetPackConfig.NetPackConfigItem>> _packageConfigs = new MutableLiveData<> ();

	public MutableLiveData<Integer> getAction () {
		return _action;
	}
	public MutableLiveData<ArrayList<NetPackConfig.NetPackConfigItem>> getPackageConfigs () {
		return _packageConfigs;
	}

	private void endOfDownload (final Activity activity, final boolean showFailedAlert, final String downloadedFile, final boolean doGen, final String packageNameFull) {
		activity.runOnUiThread (new Runnable () {
			@Override
			public void run () {
				if (showFailedAlert) {
					_action.postValue (SHOW_FAILED_ALERT);

//					if (downloadedFile) {
//						[[NSFileManager defaultManager] removeItemAtURL:downloadedFile error:nil];
//					}
//
//					UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
//					message:@"Error occured during download!"
//					preferredStyle:UIAlertControllerStyleAlert];
//
//					UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"OK"
//					style:UIAlertActionStyleDefault
//					handler:^(UIAlertAction * action) {
//																		 [self dismissView];
//					}];
//
//					[alert addAction:okButton];
//					[self presentViewController:alert animated:YES completion:nil];
				} else {
					if (doGen) {
						_action.postValue (SHOW_GEN_VIEW);

//						NSString *packageName = packageNameFull;
//						NSString *ext = [packageNameFull pathExtension];
//						if ([ext length] > 0) {
//							packageName = [packageNameFull substringToIndex:[packageNameFull length] - [ext length] - 1];
//						}
//
//						NSArray<Package*> *packages = [[PackageManager sharedInstance] collectPackages];
//
//						[packages enumerateObjectsUsingBlock:^(Package * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//							NSString *testPackageName = [[obj path] lastPathComponent];
//							if ([testPackageName compare:packageName] == NSOrderedSame) {
//								self->_decks = [obj decks];
//								*stop = YES;
//							}
//						}];
//
//						if ([self->_decks count] > 0) {
//							[self performSegueWithIdentifier:@"ShowGen" sender:self];
//						} else {
//							[self dismissView];
//						}
					} else {
						_action.postValue (DISMISS_VIEW);
					}
				}

			}
		});
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
						NetLogger.logEvent ("Obtain_NetPackage_Failed", new HashMap<String, Object> () {{
							put ("url", url);
						}});
						break;
					case DownloadResult_Cancelled:
						NetLogger.logEvent ("Obtain_NetPackage_Cancelled", new HashMap<String, Object> () {{
							put ("url", url);
						}});
						break;
					default:
						NetLogger.logEvent ("Obtain_NetPackage_Unknown", new HashMap<String, Object> () {{
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

	public void startDownloadPackage (final Activity activity, final NetPackConfig.NetPackConfigItem configItem) {
		final String url = getDownloadLinkForGoogleDrive (configItem.fileID);

		NetLogger.logEvent ("Obtain_NetPackage_Selected", new HashMap<String, Object> () {{
			put ("label", configItem.label);
			put ("url", url);
		}});

		downloadFileFromGoogleDrive (activity, url, true, new ContentHandler () {
			@Override
			public void apply (String downloadedFile, String fileName) {
//				[NetLogger logEvent:@"Obtain_NetPackage_Downloaded" withParameters:@{ @"label" : configItem.label, @"url" : [url absoluteString], @"fileName" : fileName }];
//
//					//Unzip downloaded file to packages
//				[[PackageManager sharedInstance] unzipDownloadedPackage:downloadedFile packageName:[fileName stringByDeletingPathExtension]];
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

	public void cancelDownload () {
		if (_downloader != null) {
			_downloader.cancel ();
		}
	}

	private void updateProgress (long pos, long size) {
//		dispatch_async (dispatch_get_main_queue (), ^{
//			NSString *progress = [Downloader createDataProgressLabel:pos size:size];
//			NSString *label = [NSString stringWithFormat:@"%@", progress];
//			[self->_progressView setLabelContent:label];
//
//			if (size > 0) {
//				float percent = (float)pos / (float)size;
//				[self->_progressView setProgressValue:percent];
//			}
//		});
	}
}
