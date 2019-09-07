package com.zapp.acw.ui.main;

import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.zapp.acw.R;
import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.SavedCrossword;

import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;
import java.util.HashMap;

public class MainFragment extends Fragment {

	private MainViewModel _viewModel;
	private Timer _timer;
	private int _animCounter = 0;
	private boolean _packagesLoaded = false;
	private boolean _crosswordsLoaded = false;

	public static MainFragment newInstance () {
		return new MainFragment ();
	}

	@Nullable
	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		View view = inflater.inflate (R.layout.main_fragment, container, false);
		view.setSystemUiVisibility (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
				| View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
				| View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
				| View.SYSTEM_UI_FLAG_HIDE_NAVIGATION // hide nav bar
				| View.SYSTEM_UI_FLAG_FULLSCREEN // hide status bar
				| View.SYSTEM_UI_FLAG_IMMERSIVE);
		return view;
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);
		_viewModel = ViewModelProviders.of (this).get (MainViewModel.class);

		_viewModel.getPackages ().observe (getViewLifecycleOwner (), new Observer<ArrayList<Package>> () {
			@Override
			public void onChanged (ArrayList<Package> packages) {
				_packagesLoaded = packages != null;
			}
		});
		_viewModel.getSavedCrosswords ().observe (getViewLifecycleOwner (), new Observer<HashMap<String, ArrayList<SavedCrossword>>> () {
			@Override
			public void onChanged (HashMap<String, ArrayList<SavedCrossword>> savedCrosswords) {
				_crosswordsLoaded = savedCrosswords != null;
			}
		});
		_viewModel.startLoad ();

		_timer = new Timer ();
		_timer.schedule (new TimerTask () {
			@Override
			public void run () {
				if (_animCounter >= 6 && _packagesLoaded && _crosswordsLoaded) {
					_timer.cancel ();
					_timer.purge ();

					if (hasNonEmptyPackage ()) { //There are some package already downloaded
						Navigation.findNavController (getView ()).navigate (R.id.ShowChooseCW);
					} else { // No packages found
						Navigation.findNavController (getView ()).navigate (R.id.ShowDownload);
					}
				} else {
					++_animCounter;
				}
			}
		}, 300, 300);
	}

	private boolean hasNonEmptyPackage () {
		boolean res = false;
		HashMap<String, ArrayList<SavedCrossword>> savedCrosswords = _viewModel.getSavedCrosswords ().getValue ();
		ArrayList<Package> packages = _viewModel.getPackages ().getValue ();
		for (Package pack : packages) {
			String packageKey = pack.path.substring (pack.path.lastIndexOf ('/') + 1);
			ArrayList<SavedCrossword> cws = savedCrosswords.get (packageKey);
			if (cws != null && cws.size () > 0) {
				res = true;
				break;
			}
		}
		return res;
	}
}
