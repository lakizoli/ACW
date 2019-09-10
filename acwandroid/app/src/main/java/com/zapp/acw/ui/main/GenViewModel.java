package com.zapp.acw.ui.main;

import androidx.lifecycle.ViewModel;

import com.zapp.acw.bll.Deck;
import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.GeneratorInfo;
import com.zapp.acw.bll.PackageManager;

import java.util.ArrayList;

public class GenViewModel extends ViewModel {
	private GeneratorInfo _generatorInfo;
	private Package _package;
	private ArrayList<Deck> _decks;

	// TODO: Implement the ViewModel

	public void init (Package pack) {
		_package = pack;
		_decks = _package.decks;
		_generatorInfo = PackageManager.sharedInstance ().collectGeneratorInfo (_decks);
	}
}
