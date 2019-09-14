package com.zapp.acw.bll;

import android.content.Context;
import android.content.DialogInterface;

import com.zapp.acw.R;

import androidx.appcompat.app.AlertDialog;

public final class SubscriptionManager {
	private static SubscriptionManager _instance = new SubscriptionManager ();

	private SubscriptionManager () {
	}

	public static SubscriptionManager sharedInstance () {
		return _instance;
	}


	public void showSubscriptionAlert (Context context, String msg) {
		AlertDialog.Builder builder = new AlertDialog.Builder (context);
		builder.setTitle ("Subscribe Alert!");
		builder.setNegativeButton (R.string.no, new DialogInterface.OnClickListener () {
			@Override
			public void onClick (DialogInterface dialog, int which) {
				// ... Nothing to do here ...
			}
		});

		builder.setPositiveButton (R.string.yes, new DialogInterface.OnClickListener () {
			@Override
			public void onClick (DialogInterface dialog, int which) {
				//TODO: show store...
			}
		});

		builder.show ();
	}

	public boolean isSubscribed () {
		return false;
	}
}
