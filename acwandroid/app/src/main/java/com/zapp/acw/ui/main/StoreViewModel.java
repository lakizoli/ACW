package com.zapp.acw.ui.main;

import android.app.Activity;
import android.content.res.Resources;
import android.util.Log;

import com.android.billingclient.api.SkuDetails;
import com.zapp.acw.R;
import com.zapp.acw.bll.SubscriptionManager;

import java.io.InputStream;
import java.util.ArrayList;

import androidx.annotation.RawRes;

public class StoreViewModel extends BackgroundInitViewModel {
	private String _considerationsHTML;
	private String _privacyPolicyHTML;
	private String _termsOfUseHTML;

	public String getConsiderationsHTML () {
		return _considerationsHTML;
	}
	public String getPrivacyPolicyHTML () {
		return _privacyPolicyHTML;
	}
	public String getTermsOfUseHTML () {
		return _termsOfUseHTML;
	}

	public void startInit (final Activity activity) {
		startInit (new InitListener () {
			@Override
			public void initInBackground () {
				_considerationsHTML = readRAWResourceFile (activity, R.raw.considerations);
				_privacyPolicyHTML = readRAWResourceFile (activity, R.raw.privacy_policy);
				_termsOfUseHTML = readRAWResourceFile (activity, R.raw.terms_of_use);

				//Localize store html
				Resources res = activity.getResources ();
				int idx;
				while ((idx = _considerationsHTML.indexOf ("##loc_")) >= 0) {
					int endIdx = _considerationsHTML.indexOf ("##", idx + 1);
					String locID = _considerationsHTML.substring (idx + 6, endIdx);
					int resID = res.getIdentifier (locID, "string", activity.getPackageName ());
					String locValue = res.getString (resID);
					_considerationsHTML = _considerationsHTML.replaceAll ("##loc_" + locID + "##",  locValue);
				}

				//Fill prices
				SubscriptionManager man = SubscriptionManager.sharedInstance ();
				SkuDetails product = man.getSubscribedProductForMonth ();
				if (product != null) {
					String price = product.getPrice ().replaceAll ("\\$", "\\\\\\$");
					_considerationsHTML = _considerationsHTML.replaceAll ("##MonthlyPrice##",  price + res.getString (R.string.sc_per_month));
				}

				product = man.getSubscribedProductForYear ();
				if (product != null) {
					String price = product.getPrice ().replaceAll ("\\$", "\\\\\\$");
					_considerationsHTML = _considerationsHTML.replaceAll ("##YearlyPrice##", price  + res.getString (R.string.sc_per_year));
				}
			}
		});
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
