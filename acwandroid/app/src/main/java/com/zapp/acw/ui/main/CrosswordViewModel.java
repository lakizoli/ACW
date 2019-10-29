package com.zapp.acw.ui.main;

import android.os.Bundle;

import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.Pos;
import com.zapp.acw.bll.SavedCrossword;

import java.util.ArrayList;
import java.util.HashMap;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class CrosswordViewModel extends ViewModel {
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

	public void startInit (final Bundle args) {
		new Thread (new Runnable () {
			@Override
			public void run () {
				//Parse paramteres
				currentPackage = args.getParcelable ("package");
				savedCrossword = args.getParcelable ("savedCrossword");
				currentCrosswordIndex = args.getInt ("currentCrosswordIndex");
				allSavedCrossword = args.getParcelableArrayList ("allSavedCrossword");
				isMultiLevelGame = args.getBoolean ("isMultiLevelGame");

				//Load database info
				cellFilledValues = new HashMap<> ();
				savedCrossword.loadFilledValuesInto (cellFilledValues);
				savedCrossword.loadDB ();

				//Init ended
				_action.postValue (ActionCodes.CWVIEW_INIT_ENDED);
			}
		}).start ();
	}
}
