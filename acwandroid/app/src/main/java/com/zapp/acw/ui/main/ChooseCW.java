package com.zapp.acw.ui.main;

import androidx.lifecycle.ViewModelProviders;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.zapp.acw.R;

public class ChooseCW extends Fragment {

	private ChooseCWViewModel mViewModel;

	public static ChooseCW newInstance () {
		return new ChooseCW ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.choose_cw_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);
		mViewModel = ViewModelProviders.of (this).get (ChooseCWViewModel.class);
		// TODO: Use the ViewModel
	}

}