package com.zapp.acw.ui.main;

import android.os.Handler;

import androidx.lifecycle.ViewModel;

public abstract class BackgroundInitViewModel extends ViewModel {
	private Handler mHandler = new Handler ();
	private InitEndedObserver mInitEndedObserver;

	public interface InitEndedObserver {
		void onInitEnded ();
	}

	public void setInitEndedObserver (InitEndedObserver initEndedObserver) {
		mInitEndedObserver = initEndedObserver;
	}

	public interface InitListener {
		void initInBackground ();
	}

	protected void startInit (final InitListener initListener) {
		new Thread (new Runnable () {
			@Override
			public void run () {
				initListener.initInBackground ();

				mHandler.post (new Runnable () {
					@Override
					public void run () {
						if (mInitEndedObserver != null) {
							mInitEndedObserver.onInitEnded ();
						}
					}
				});
			}
		}).start ();
	}
}
