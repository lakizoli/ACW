package com.zapp.acw.ui.main;

import android.app.Activity;

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
		new Thread (new Runnable () {
			@Override
			public void run () {
				PackageManager man = PackageManager.sharedInstance ();
				final ArrayList<Package> packages = man.collectPackages ();
				final HashMap<String, ArrayList<SavedCrossword>> cws = man.collectSavedCrosswords ();

				_packages.postValue (packages);
				_savedCrosswords.postValue (cws);
			}
		}).start ();
	}

	public MutableLiveData<ArrayList<Package>> getPackages () {
		return _packages;
	}

	public MutableLiveData<HashMap<String, ArrayList<SavedCrossword>>> getSavedCrosswords () {
		return _savedCrosswords;
	}
}
