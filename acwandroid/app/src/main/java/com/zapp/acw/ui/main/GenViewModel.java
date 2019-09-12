package com.zapp.acw.ui.main;

import com.zapp.acw.bll.Card;
import com.zapp.acw.bll.Deck;
import com.zapp.acw.bll.Field;
import com.zapp.acw.bll.GeneratorInfo;
import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.PackageManager;

import java.util.ArrayList;

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class GenViewModel extends ViewModel {
	public final static int GENERATION_ENDED = 1;

	private MutableLiveData<Integer> _action = new MutableLiveData<> ();
	private MutableLiveData<GeneratorInfo> _generatorInfo = new MutableLiveData<> ();
	private Package _package;
	private ArrayList<Deck> _decks;
	private int _questionFieldIndex = -1;
	private int _solutionFieldIndex = -1;

	public MutableLiveData<Integer> getAction () {
		return _action;
	}
	public MutableLiveData<GeneratorInfo> getGeneratorInfo () {
		return _generatorInfo;
	}
	public Package getPackage () {
		return _package;
	}
	public ArrayList<Deck> getDecks () {
		return _decks;
	}
	public void setQuestionFieldIndex (int questionFieldIndex) {
		_questionFieldIndex = questionFieldIndex;
	}
	public void setSolutionFieldIndex (int solutionFieldIndex) {
		_solutionFieldIndex = solutionFieldIndex;
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

	public void startGeneration () {
		if (_questionFieldIndex < 0 || _solutionFieldIndex < 0) {
			return;
		}

		//Fill generation info for full generation
		GeneratorInfo info = _generatorInfo.getValue ();

		info.crosswordName = "cw";
		info.width = 25;
		info.height = 25;
		info.questionFieldIndex = _questionFieldIndex;
		info.solutionFieldIndex = _solutionFieldIndex;

		//Generate crossword
		new Thread (new Runnable () {
			@Override
			public void run () {
				try {
					Thread.currentThread ().wait (1000);
				}catch (Exception ex) {
					ex.printStackTrace ();
				}
				//TODO: ...

				_action.postValue (GENERATION_ENDED);
			}
		}).start ();
	}

	public void cancelGeneration () {
	}
}
