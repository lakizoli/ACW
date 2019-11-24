package com.zapp.acw.ui.main;

import android.os.Bundle;

import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.PackageManager;
import com.zapp.acw.bll.Pos;
import com.zapp.acw.bll.SavedCrossword;

import java.util.ArrayList;
import java.util.HashMap;

import androidx.lifecycle.MutableLiveData;

public class CrosswordViewModel extends BackgroundInitViewModel {
	private boolean isMultiLevelGame;
	private Package currentPackage;
	private int currentCrosswordIndex;
	private SavedCrossword savedCrossword;
	private ArrayList<SavedCrossword> allSavedCrossword;
	private HashMap<Pos, String> cellFilledValues;

	private MutableLiveData<Integer> _action = new MutableLiveData<> ();

	public MutableLiveData<Integer> getAction () {
		return _action;
	}
	public boolean getIsMultiLevelGame () {
		return isMultiLevelGame;
	}
	public Package getCurrentPackage () {
		return currentPackage;
	}
	public int getCurrentCrosswordIndex () {
		return currentCrosswordIndex;
	}
	public SavedCrossword getSavedCrossword () {
		return savedCrossword;
	}
	public ArrayList<SavedCrossword> getAllSavedCrossword () {
		return allSavedCrossword;
	}
	public HashMap<Pos, String> getCellFilledValues () {
		return cellFilledValues;
	}

	public boolean wasHelpShownBeforeRotation = false;
	public boolean wasTapHelpShownBeforeRotation = false;
	public boolean wasGameHelpShownBeforeRotation = false;

	public void startInit (final Bundle args) {
		startInit (new InitListener () {
			@Override
			public void initInBackground () {
				//Parse paramteres
				currentPackage = args.getParcelable ("package");
				savedCrossword = args.getParcelable ("savedCrossword");
				currentCrosswordIndex = args.getInt ("currentCrosswordIndex");
				allSavedCrossword = args.getParcelableArrayList ("allSavedCrossword");
				isMultiLevelGame = args.getBoolean ("isMultiLevelGame");

				//Reload package state
				PackageManager.sharedInstance ().loadPackageState (currentPackage);

				//Load database info
				cellFilledValues = new HashMap<> ();
				savedCrossword.loadFilledValuesInto (cellFilledValues);
				savedCrossword.loadDB ();
			}
		});
	}
}
