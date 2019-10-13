package com.zapp.acw.bll;

import android.content.Context;
import android.content.DialogInterface;
import android.view.View;

import com.zapp.acw.R;

import androidx.appcompat.app.AlertDialog;
import androidx.navigation.Navigation;

public final class SubscriptionManager {
	private static SubscriptionManager _instance = new SubscriptionManager ();

	private String mPendingSubscriptionAlert = null;

	private SubscriptionManager () {
	}

	public static SubscriptionManager sharedInstance () {
		return _instance;
	}

	public void setPendingSubscriptionAlert (String msg) {
		mPendingSubscriptionAlert = msg;
	}

	public String popPendingSubscriptionAlert () {
		String msg = mPendingSubscriptionAlert;
		mPendingSubscriptionAlert = null;
		return msg;
	}

	public void showSubscriptionAlert (Context context, final View view, String msg) {
		AlertDialog.Builder builder = new AlertDialog.Builder (context);
		builder.setTitle ("Subscribe Alert!");

		builder.setMessage (msg);

		builder.setNegativeButton (R.string.no, new DialogInterface.OnClickListener () {
			@Override
			public void onClick (DialogInterface dialog, int which) {
				// ... Nothing to do here ...
			}
		});
		builder.setPositiveButton (R.string.yes, new DialogInterface.OnClickListener () {
			@Override
			public void onClick (DialogInterface dialog, int which) {
				Navigation.findNavController (view).navigate (R.id.ShowStore);
			}
		});

		builder.show ();
	}

	public boolean isSubscribed () {
		return false;
	}
}
