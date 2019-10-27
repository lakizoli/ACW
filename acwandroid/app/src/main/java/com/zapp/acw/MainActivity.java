package com.zapp.acw;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;

import com.zapp.acw.bll.PackageManager;
import com.zapp.acw.bll.SubscriptionManager;
import com.zapp.acw.ui.main.MainFragment;

public class MainActivity extends AppCompatActivity {
	static {
		System.loadLibrary ("NativeACW");
	}

	@Override
	protected void onCreate (Bundle savedInstanceState) {
		super.onCreate (savedInstanceState);

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
}
