package com.zapp.acw.ui.main;

import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.PackageManager;
import com.zapp.acw.bll.SavedCrossword;

import java.util.ArrayList;
import java.util.HashMap;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class MainViewModel extends ViewModel {
	private final MutableLiveData<ArrayList<Package>> _packages = new MutableLiveData<> ();
	private final MutableLiveData<HashMap<String, ArrayList<SavedCrossword>>> _savedCrosswords = new MutableLiveData<> ();

	public void startLoad () {
		PackageManager man = PackageManager.sharedInstance ();
		_packages.setValue (man.collectPackages ());
		_savedCrosswords.setValue (man.collectSavedCrosswords ());
	}

	public MutableLiveData<ArrayList<Package>> getPackages () {
		return _packages;
	}
	public MutableLiveData<HashMap<String, ArrayList<SavedCrossword>>> getSavedCrosswords () {
		return _savedCrosswords;
	}
}
