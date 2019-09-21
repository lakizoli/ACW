package com.zapp.acw.ui.main;

import android.os.Bundle;

import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.SavedCrossword;

import java.util.ArrayList;

import androidx.lifecycle.ViewModel;

public class CrosswordViewModel extends ViewModel {
	private boolean isMultiLevelGame;
	private Package currentPackage;
	private int currentCrosswordIndex;
	private SavedCrossword savedCrossword;
	private ArrayList<SavedCrossword> allSavedCrossword;

	public boolean getIsMultiLevelGame () { return isMultiLevelGame; }
	public Package getCurrentPackage () { return currentPackage; }
	public int getCurrentCrosswordIndex () { return currentCrosswordIndex; }
	public SavedCrossword getSavedCrossword () { return savedCrossword; }
	public ArrayList<SavedCrossword> getAllSavedCrossword () { return allSavedCrossword; }

	public void init (Bundle args) {
		currentPackage = args.getParcelable ("package");
		savedCrossword = args.getParcelable ("savedCrossword");
		currentCrosswordIndex = args.getInt ("currentCrosswordIndex");
		allSavedCrossword = args.getParcelableArrayList ("allSavedCrossword");
		isMultiLevelGame = args.getBoolean ("isMultiLevelGame");
	}
}
