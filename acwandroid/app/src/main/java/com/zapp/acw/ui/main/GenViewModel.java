package com.zapp.acw.ui.main;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.zapp.acw.bll.Card;
import com.zapp.acw.bll.Deck;
import com.zapp.acw.bll.Field;
import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.GeneratorInfo;
import com.zapp.acw.bll.PackageManager;

import java.util.ArrayList;

public class GenViewModel extends ViewModel {
	private MutableLiveData<GeneratorInfo> _generatorInfo = new MutableLiveData<> ();
	private Package _package;
	private ArrayList<Deck> _decks;

	public MutableLiveData<GeneratorInfo> getGeneratorInfo () {
		return _generatorInfo;
	}
	public Package getPackage () {
		return _package;
	}
	public ArrayList<Deck> getDecks () {
		return _decks;
	}

	public void startCollectGeneratorInfo (Package pack) {
		_package = pack;
		_decks = _package.decks;

		new Thread (new Runnable () {
			@Override
			public void run () {
				GeneratorInfo generatorInfo = PackageManager.sharedInstance ().collectGeneratorInfo (_decks);
				_generatorInfo.postValue (generatorInfo);
			}
		}).start ();
	}

	public String getFieldValue (Field field) {
		String fieldValue = "";

		GeneratorInfo generatorInfo = _generatorInfo.getValue ();
		if (generatorInfo != null) {
			ArrayList<Card> cards = generatorInfo.cards;

			if (cards != null && cards.size () > 0) {
				Card card = cards.get (0);
				if (card.fieldValues != null && field.idx < card.fieldValues.size ()) {
					fieldValue = card.fieldValues.get ((int) field.idx);
				}
			}
		}

		return fieldValue;
	}
}
