package com.zapp.acw.ui.main;

import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;

import com.zapp.acw.R;

public class StoreFragment extends Fragment {

	private StoreViewModel mViewModel;

	public static StoreFragment newInstance () {
		return new StoreFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.store_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);

		mViewModel = ViewModelProviders.of (this).get (StoreViewModel.class);

		final FragmentActivity activity = getActivity ();

		mViewModel.getAction ().observe (getViewLifecycleOwner (), new Observer<Integer> () {
			@Override
			public void onChanged (Integer action) {
				switch (action) {
					case StoreViewModel.LOAD_STORE_ENDED: {
						WebView webView = activity.findViewById (R.id.store_webview);
						webView.loadDataWithBaseURL ("file:///android_asset/",
							mViewModel.getConsiderationsHTML (),
							"text/html",
							"UTF-8",
							"about:blank");
						break;
					}
					default:
						break;
				}
			}
		});

		mViewModel.startLoad (activity);
	}
}
