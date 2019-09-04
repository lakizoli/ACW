package com.zapp.acw;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;

import com.zapp.acw.bll.PackageManager;
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
	}
}
