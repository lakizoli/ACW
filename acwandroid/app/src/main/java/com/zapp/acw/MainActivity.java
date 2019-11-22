package com.zapp.acw;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.DialogInterface;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.provider.OpenableColumns;

import com.zapp.acw.bll.NetLogger;
import com.zapp.acw.bll.PackageManager;
import com.zapp.acw.bll.SubscriptionManager;
import com.zapp.acw.ui.main.MainFragment;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;
import androidx.navigation.Navigation;

public class MainActivity extends AppCompatActivity {
	static {
		System.loadLibrary ("NativeACW");
	}

	private static Bundle startArgs = null;

	public static Bundle getStartArgs () {
		return startArgs;
	}

	@Override
	protected void onCreate (Bundle savedInstanceState) {
		super.onCreate (savedInstanceState);

		NetLogger.startSession (this, getFilesDir ().getAbsolutePath () + "/events");
		new Thread (new Runnable () {
			@Override
			public void run () {
				NetLogger.sendAllEventFromFiles ();
			}
		}).start ();

		final MainActivity activity = this;
		SubscriptionManager.sharedInstance ().setActivityProvider (new SubscriptionManager.ActivityProvider () {
			@Override
			public Activity getActivity () {
				return activity;
			}
		});

		String openInFileName = OpenIn ();
		if (openInFileName != null) { //If a file has been opened in the app
			startArgs = MainFragment.buildStartArgs (openInFileName);
		}

		PackageManager man = PackageManager.sharedInstance ();
		man.applicationContext = getApplicationContext ();

		setContentView (R.layout.main_activity);

		Common.setFullscreen (this);
		Common.registerSystemUiVisibility (this);
	}

	@Override
	public void onDestroy () {
		super.onDestroy ();

		Common.exitFullscreen (this);
		Common.unregisterSystemUiVisibility (this);
	}

	@Override
	protected void onResume () {
		super.onResume ();

		SubscriptionManager.sharedInstance ().queryPurchases ();
	}

	private String OpenIn () {
		Intent intent = getIntent ();
		if (intent == null) {
			return null;
		}

		Uri uri = intent.getData ();
		if (uri == null) {
			return null;
		}

		intent.setData (null);

		//Importing data
		InputStream is = null;
		FileOutputStream fos = null;
		try {
			final String scheme = uri.getScheme();

			ContentResolver cr = getContentResolver ();
			String fileName = "unknown.apkg";
			if (ContentResolver.SCHEME_FILE.equals (scheme)) {
				fileName = uri.getLastPathSegment ();
			} else if(ContentResolver.SCHEME_CONTENT.equals(scheme)) {
				Cursor cursor = cr.query (uri, null, null, null, null);
				if (cursor != null && cursor.moveToFirst ()) {
					fileName = cursor.getString (cursor.getColumnIndex (OpenableColumns.DISPLAY_NAME));
				}
			} else { //Unhandled intent
				return null;
			}

			//Copy package to the doc dir
			is = cr.openInputStream (uri);

			File file = new File (getFilesDir ().getAbsolutePath (), fileName);
			if (file.exists ()) {
				FileUtils.deleteRecursive (file.getAbsolutePath ());
			}

			fos = new FileOutputStream (file);

			int avail;
			while ((avail = is.available ()) > 0) {
				int chunkSize = 1024*1024;
				int chunkCount = avail / chunkSize;
				if (avail % chunkSize > 0) {
					++chunkCount;
				}

				byte[] buffer = new byte[chunkSize];
				for (int chunk = 0; chunk < chunkCount; ++chunk) {
					int readCnt = chunk == chunkCount - 1 ? avail % chunkSize : chunkSize;

					if (is.read (buffer, 0, readCnt) != readCnt) {
						throw new Exception ("Cannot read file!");
					}

					fos.write (buffer, 0, readCnt);
				}
			}

			return FileUtils.pathByDeletingPathExtension (fileName);
		} catch (Exception ex) {
			AlertDialog.Builder builder = new AlertDialog.Builder (this);

			builder.setTitle ("Import error!");
			builder.setMessage ("Cannot import file!");
			builder.setPositiveButton (R.string.ok, new DialogInterface.OnClickListener () {
				@Override
				public void onClick (DialogInterface dialog, int which) {
					// ... Nothing to do here ...
				}
			});

			builder.show ();
		} finally {
			try {
				if (is != null) {
					is.close ();
				}
			} catch (Exception ex) {
			}

			try {
				if (fos != null) {
					fos.close ();
				}
			} catch (Exception ex) {
			}
		}

		return null;
	}
}
