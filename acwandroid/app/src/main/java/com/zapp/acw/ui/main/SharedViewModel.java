package com.zapp.acw.ui.main;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import java.util.ArrayList;
import java.util.TreeMap;

public class SharedViewModel extends ViewModel {
	private final MutableLiveData<ArrayList<Object>> _packages = new MutableLiveData<> (); //TODO: change Object to Package
	private final MutableLiveData<TreeMap<String, ArrayList<Object>>> _savedCrosswords = new MutableLiveData<> (); //TODO: change Object to SaveCrossword

	public void startLoad () {
		//TODO: implement load of packages in background
		_packages.setValue (null);
	}

	public MutableLiveData<ArrayList<Object>> getPackages () {
		return _packages;
	}
}
