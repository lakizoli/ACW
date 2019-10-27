package com.zapp.acw.ui.main;

import android.app.Activity;
import android.content.res.Resources;
import android.util.Log;

import com.zapp.acw.R;

import java.io.FileInputStream;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Arrays;

import androidx.annotation.IdRes;
import androidx.annotation.RawRes;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class StoreViewModel extends ViewModel {
	public static final int LOAD_STORE_ENDED = 1;

	private MutableLiveData<Integer> _action = new MutableLiveData<> ();

	private String _considerationsHTML;
	private String _privacyPolicyHTML;
	private String _termsOfUseHTML;

	public MutableLiveData<Integer> getAction () {
		return _action;
	}

	public String getConsiderationsHTML () {
		return _considerationsHTML;
	}

	public String getPrivacyPolicyHTML () {
		return _privacyPolicyHTML;
	}

	public String getTermsOfUseHTML () {
		return _termsOfUseHTML;
	}

	public void startLoad (final Activity activity) {
		new Thread (new Runnable () {
			@Override
			public void run () {
				_considerationsHTML = readRAWResourceFile (activity, R.raw.considerations);
				_privacyPolicyHTML = readRAWResourceFile (activity, R.raw.privacy_policy);
				_termsOfUseHTML = readRAWResourceFile (activity, R.raw.terms_of_use);

				_action.postValue (LOAD_STORE_ENDED);
			}
		}).start ();
	}

	private static String readRAWResourceFile (Activity activity, @RawRes int id) {
		InputStream is = null;
		try {
			is = activity.getResources ().openRawResource (id);

			ArrayList<Byte> content = new ArrayList<> ();
			int avail = 0;
			while ((avail = is.available ()) > 0) {
				byte[] buffer = new byte[avail];
				if (is.read (buffer) != avail) {
					return null;
				}

				for (byte b : buffer) {
					content.add (b);
				}
			}

			byte[] fullContent = new byte[content.size ()];
			for (int i = 0, iEnd = content.size (); i < iEnd; ++i) {
				fullContent[i] = content.get (i);
			}

			return new String (fullContent);
		} catch (Exception ex) {
			Log.e ("FileUtils", "readRAWResourceFile exception (1): " + ex);
		} finally {
			try {
				if (is != null) {
					is.close ();
				}
			} catch (Exception ex) {
				Log.e ("FileUtils", "readRAWResourceFile exception (2): " + ex);
			}
		}

		return null;
	}
}
