package com.zapp.acw;

import android.annotation.TargetApi;
import android.app.Activity;
import android.os.Build;
import android.view.View;
import android.view.WindowManager;

public final class Common {

	//region Fullscreen mode handling
	private static boolean isImmersiveAvailable () {
		return android.os.Build.VERSION.SDK_INT >= 19;
	}

	public static void setFullscreen (Activity activity) {
		int flags = View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_FULLSCREEN;

		if (isImmersiveAvailable ()) {
			flags |= View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
				View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
		}

		activity.getWindow ().getDecorView ().setSystemUiVisibility (flags);
	}

	public static void exitFullscreen (Activity activity) {
		activity.getWindow ().getDecorView ().setSystemUiVisibility (View.SYSTEM_UI_FLAG_VISIBLE);
	}

	public static void registerSystemUiVisibility (final Activity activity) {
		final View decorView = activity.getWindow ().getDecorView ();
		decorView.setOnSystemUiVisibilityChangeListener (new View.OnSystemUiVisibilityChangeListener () {
			@Override
			public void onSystemUiVisibilityChange (int visibility) {
				if ((visibility & View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
					setFullscreen (activity);
				}
			}
		});
	}

	public static void unregisterSystemUiVisibility (Activity activity) {
		final View decorView = activity.getWindow ().getDecorView ();
		decorView.setOnSystemUiVisibilityChangeListener (null);
	}
	//endregion
}
