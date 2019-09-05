package com.zapp.acw.ui.main;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.PackageManager;
import com.zapp.acw.bll.SavedCrossword;

import java.util.ArrayList;
import java.util.TreeMap;

public class MainViewModel extends ViewModel {
	private final MutableLiveData<ArrayList<Package>> _packages = new MutableLiveData<> ();
	private final MutableLiveData<TreeMap<String, ArrayList<SavedCrossword>>> _savedCrosswords = new MutableLiveData<> ();

	public void startLoad () {
		PackageManager man = PackageManager.sharedInstance ();
		_packages.setValue (man.collectPackages ());
		//TODO: implement load of saved crosswords in background
		_savedCrosswords.setValue (null);
	}

	public MutableLiveData<ArrayList<Package>> getPackages () {
		return _packages;
	}
	public MutableLiveData<TreeMap<String, ArrayList<SavedCrossword>>> getSavedCrosswords () {
		return _savedCrosswords;
	}
}
