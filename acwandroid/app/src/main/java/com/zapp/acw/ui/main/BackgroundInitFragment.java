package com.zapp.acw.ui.main;

import android.content.Context;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.view.Surface;
import android.view.WindowManager;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

public class BackgroundInitFragment extends Fragment {
	private boolean mIsInInit = false;

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);
		mIsInInit = true;
		lockOrientation ();
	}

	protected void endInit () {
		mIsInInit = false;
		unlockOrientation ();
	}

	protected boolean isInInit () {
		return mIsInInit;
	}

	protected void lockOrientation () {
		int orientation = getActivity ().getRequestedOrientation ();
		int rotation = ((WindowManager) getActivity ().getSystemService (Context.WINDOW_SERVICE)).getDefaultDisplay ().getRotation ();
		switch (rotation) {
			case Surface.ROTATION_0:
				orientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
				break;
			case Surface.ROTATION_90:
				orientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
				break;
			case Surface.ROTATION_180:
				orientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
				break;
			default:
				orientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
				break;
		}

		getActivity ().setRequestedOrientation (orientation);
	}

	protected void unlockOrientation () {
		getActivity ().setRequestedOrientation (ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
	}
}