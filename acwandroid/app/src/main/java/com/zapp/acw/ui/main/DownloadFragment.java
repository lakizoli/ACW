package com.zapp.acw.ui.main;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.google.android.material.tabs.TabLayout;
import com.zapp.acw.R;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.ViewModelProviders;

public class DownloadFragment extends Fragment implements TabLayout.OnTabSelectedListener {

	private DownloadViewModel mViewModel;

	public static DownloadFragment newInstance () {
		return new DownloadFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.download_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);
		mViewModel = ViewModelProviders.of (this).get (DownloadViewModel.class);
		// TODO: Use the ViewModel

		//Init tab bar
		FragmentActivity activity = getActivity ();
		TabLayout tabLayout = activity.findViewById(R.id.tab_layout);
		tabLayout.addOnTabSelectedListener (this);
		TabLayout.Tab tab = tabLayout.getTabAt (0);
		tab.select();
	}

	@Override
	public void onTabSelected (TabLayout.Tab tab) {
		Log.d ("AAA", "1");
	}

	@Override
	public void onTabUnselected (TabLayout.Tab tab) {
		Log.d ("AAA", "1");
	}

	@Override
	public void onTabReselected (TabLayout.Tab tab) {
		Log.d ("AAA", "1");
	}
}
