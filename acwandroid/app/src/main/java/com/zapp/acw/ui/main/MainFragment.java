package com.zapp.acw.ui.main;

import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.zapp.acw.R;

import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

public class MainFragment extends Fragment {

	private SharedViewModel _viewModel;
	private Timer _timer;
	private int _animCounter = 0;
	private boolean _hasCollectedPackages = false;

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
		_viewModel = ViewModelProviders.of (this).get (SharedViewModel.class);

		_viewModel.getPackages ().observe (this, new Observer<ArrayList<Object>> () {
			@Override
			public void onChanged (ArrayList<Object> objects) {
				_hasCollectedPackages = objects != null;
			}
		});
		_viewModel.startLoad ();

		_timer = new Timer ();
		_timer.schedule (new TimerTask () {
			@Override
			public void run () {
				if (_animCounter >= 6 && _hasCollectedPackages) {
					_timer.cancel ();
					_timer.purge ();

					if (hasNonEmptyPackage ()) { //There are some package already downloaded
//						[self performSegueWithIdentifier:@"ShowChooseCW" sender:self];
					} else { // No packages found
//						[self performSegueWithIdentifier:@"ShowDownload" sender:self];
					}
				} else {
					++_animCounter;
				}
			}
		}, 300, 300);
	}

	private boolean hasNonEmptyPackage () {
		boolean res = false;
		ArrayList<Object> packages = _viewModel.getPackages ().getValue ();
		for (Object pack : packages) {
//			if ([[self->_savedCrosswords objectForKey:packageKey] count] > 0) {
//				res = true;
//				break;
//			}
		}
		return res;
	}
}
