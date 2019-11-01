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

import static android.icu.text.Normalizer.YES;

public class GenViewModel extends ViewModel {
	public final static int GENERATION_ENDED = 1;

	private MutableLiveData<Integer> _action = new MutableLiveData<> ();
	private MutableLiveData<Integer> _labelIndex = new MutableLiveData<> ();
	private MutableLiveData<Integer> _progress = new MutableLiveData<> ();
	private MutableLiveData<GeneratorInfo> _generatorInfo = new MutableLiveData<> ();
	private Package _package;
	private ArrayList<Deck> _decks;
	private int _questionFieldIndex = -1;
	private int _solutionFieldIndex = -1;
	private boolean _isGenerationCancelled = false;

	public MutableLiveData<Integer> getAction () {
		return _action;
	}
	public MutableLiveData<Integer> getLabelIndex () {
		return _labelIndex;
	}
	public MutableLiveData<Integer> getProgress () {
		return _progress;
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

	public int getQuestionFieldIndex () {
		return _questionFieldIndex;
	}
	public void setQuestionFieldIndex (int questionFieldIndex) {
		_questionFieldIndex = questionFieldIndex;
	}

	public int getSolutionFieldIndex () {
		return _solutionFieldIndex;
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

		_isGenerationCancelled = false;

		//Fill generation info for full generation
		final GeneratorInfo info = _generatorInfo.getValue ();

		info.crosswordName = "cw";
		info.width = 25;
		info.height = 25;
		info.questionFieldIndex = _questionFieldIndex;
		info.solutionFieldIndex = _solutionFieldIndex;

		//Generate crossword
		new Thread (new Runnable () {
			@Override
			public void run () {
				final int[] lastPercent = {-1};
				String baseName = info.crosswordName;

				String firstCWName = null;
				boolean genRes = true;
				int idx = 0;
				int cwCount = 0;
				while (genRes) {
					lastPercent[0] = -1;

					//Reload used words
					String packagePath = _decks.get (0).packagePath;
					PackageManager.sharedInstance ().reloadUsedWords (packagePath, info);

					//Add counted name to info
					String countedName = baseName + String.format (" - {%4d}", ++idx);
					info.crosswordName = countedName;

					genRes = PackageManager.sharedInstance ().generateWithInfo (info, new PackageManager.ProgressCallback () {
						@Override
						public boolean apply (float percent) {
							int percentVal = (int) (percent * 100.0f + 0.5f);
							if (percentVal != lastPercent[0]) {
								lastPercent[0] = percentVal;
								_progress.postValue (percentVal);
							}

							if (_isGenerationCancelled) {
								return false; //break generation
							}
							return true; //continue generation
						}
					});

					if (genRes) {
						++cwCount;
					}

					if (firstCWName == null) {
						firstCWName = info.crosswordName;
					}

					_labelIndex.postValue (idx);
				}

				_package.state.crosswordName = firstCWName;
				_package.state.filledLevel = 0;
				_package.state.levelCount = cwCount;
				_package.state.filledWordCount = 0;
				_package.state.wordCount = info.usedWords == null ? 0 : info.usedWords.size ();
				PackageManager.sharedInstance ().savePackageState (_package);

				//Send end action after generation
				_action.postValue (GENERATION_ENDED);
			}
		}).start ();
	}

	public void cancelGeneration () {
		_isGenerationCancelled = true;
	}
}
