package com.zapp.acw.ui.keyboard;

import android.util.SparseArray;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

public class KeyboardConfig {
	//All keyboard configuration have minimum two pages (page1: normal characters, page2: numeric, and some extra characters)
	//Altough arbitrary extra pages can be added after theese two page,
	//if the count of extra characters is not enough to cover all characters used in the crossword!
	public final static int PAGE_ALPHA = 0;
	public final static int PAGE_NUM = 1;
	public final static int BASIC_PAGE_COUNT = 2;

	//Predefined extra keys on keyboard
	public final static String BACKSPACE = "BackSpace";
	public final static String ENTER = "Done";
	public final static String SPACEBAR = "Space";
	public final static String TURNOFF = "TurnOff";
	public final static String SWITCH = "Switch";

	//region Data
	private HashSet<String> _basicKeys;
	private HashMap<Integer, Integer> _extraKeyCountsOfBasicPages;

	private int _extraPageCount;
	private int _extraPageKeyCount;
	private SparseArray<String> _extraKeyTitles;
	private SparseArray<String> _extraKeyValues;
	//endregion

	//region Interface
	public KeyboardConfig () {
		collectKeyboardKeys ();

		_extraPageCount = 0;
		_extraPageKeyCount = 29; //Must be conforming with rowKeys layout!
		_extraKeyTitles = new SparseArray<> ();
		_extraKeyValues = new SparseArray<> ();
	}

	public boolean rowKeys (int row, int page, ArrayList<String> outKeys, ArrayList<Double> outWeights) {
		if (page < BASIC_PAGE_COUNT) {
			return false; //Basic pages have to be implemented in keyboardconfigs
		}

		//Extra page
		switch (row) {
			case 0:
				outKeys.addAll (Arrays.asList ("Ex1", "Ex2", "Ex3", "Ex4", "Ex5", "Ex6", "Ex7", "Ex8", "Ex9", "Ex10", BACKSPACE));
				outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0));
				return true;
			case 1:
				outKeys.addAll (Arrays.asList ("Ex11", "Ex12", "Ex13", "Ex14", "Ex15", "Ex16", "Ex17", "Ex18", "Ex19", ENTER));
				outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0));
				return true;
			case 2:
				outKeys.addAll (Arrays.asList ("Ex20", "Ex21", "Ex22", "Ex23", "Ex24", "Ex25", "Ex26", "Ex27", "Ex28", "Ex29"));
				outWeights.addAll (Arrays.asList (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0));
				return true;
			case 3:
				outKeys.addAll (Arrays.asList (SWITCH, SPACEBAR, TURNOFF));
				outWeights.addAll (Arrays.asList (1.0, 3.0, 1.0));
				return true;
			default:
				break;
		}

		return false;
	}

	public HashSet<String> collectExtraKeys (HashSet<String> keysToCheck) {
		HashSet<String> notFoundKeys = new HashSet<> ();

		for (String obj : keysToCheck) {
			String keyToCheck = obj.toUpperCase ();
			if (!_basicKeys.contains (keyToCheck)) {
				notFoundKeys.add (keyToCheck);
			}
		}

		return notFoundKeys;
	}

	public int getExtraKeyID (String key, int page) {
		if (key.startsWith ("Ex")) {
			int extraKeyID = extraKeyIDFromPage (page, Integer.parseInt (key.substring (2)));
			if (_extraKeyValues.get (extraKeyID) != null && _extraKeyTitles.get (extraKeyID) != null) {
				return extraKeyID;
			}
		}

		return 0;
	}

	public String getValueForExtraKeyID (int extraKeyID) {
		if (extraKeyID > 0) { //Extra key
			return _extraKeyValues.get (extraKeyID);
		}

		return null;
	}

	public String getTitleForExtraKeyID (int extraKeyID) {
		if (extraKeyID > 0) { //Extra key
			return _extraKeyTitles.get (extraKeyID);
		}

		return null;
	}

	public int getPageCount () {
		return BASIC_PAGE_COUNT + _extraPageCount;
	}

	public void addExtraPages (HashSet<String> notFoundKeys) {
		//Copy keys to alloc
		ArrayList<String> keysToAlloc = new ArrayList<> ();
		keysToAlloc.addAll (notFoundKeys);

		//Fill extra keys on basic pages first
		ArrayList<Integer> sortedKeys = new ArrayList<> (_extraKeyCountsOfBasicPages.keySet ());
		Collections.sort (sortedKeys);

		for (int page : sortedKeys) {
			int availableKeyCount = _extraKeyCountsOfBasicPages.get (page);
			allocKeys (keysToAlloc, page, availableKeyCount);
		}

		//Fill remaining not found keys on etxra pages
		int remainingKeyCount = keysToAlloc.size ();
		if (remainingKeyCount > 0) {
			_extraPageCount = remainingKeyCount / _extraPageKeyCount;
			if (remainingKeyCount % _extraPageKeyCount > 0) {
				++_extraPageCount;
			}

			for (int page = 0; page < _extraPageCount; ++page) {
				allocKeys (keysToAlloc, page + BASIC_PAGE_COUNT, _extraPageKeyCount);
			}
		}
	}
	//endregion

	//region Implementation
	private void collectKeyboardKeys () {
		HashSet<String> basicKeys = new HashSet<> ();
		HashMap<Integer, Integer> extraKeyCountsOfBasicPages = new HashMap<> ();

		for (int page = 0; page < BASIC_PAGE_COUNT; ++page) {
			int extraKeyCountOnPage = 0;

			for (int row = 0; row < 4; ++row) {
				ArrayList<String> keys = new ArrayList<> ();
				ArrayList<Double> weights = new ArrayList<> ();
				if (rowKeys (row, page, keys, weights)) {
					for (String key : keys) {
						basicKeys.add (key);

						if (key.startsWith ("Ex")) { //Extra key
							++extraKeyCountOnPage;
						}
					}
				}
			}

			if (extraKeyCountOnPage > 0) {
				extraKeyCountsOfBasicPages.put (page, extraKeyCountOnPage);
			}
		}

		_basicKeys = basicKeys;
		_extraKeyCountsOfBasicPages = extraKeyCountsOfBasicPages;
	}

	private int extraKeyIDFromPage (int page, int keyIndex) {
		return page * 1000 + keyIndex;
	}

	private void allocKeys (ArrayList<String> keysToAlloc, int page, int availableKeyCount) {
		int keysToAllocCount = keysToAlloc == null ? 0 : keysToAlloc.size ();
		int allocatableKeyCount = availableKeyCount > keysToAllocCount ? keysToAllocCount : availableKeyCount; //min
		for (int i = 0; i < allocatableKeyCount; ++i) {
			int extraKeyID = extraKeyIDFromPage (page, i + 1);
			String key = keysToAlloc.get (i);

			_extraKeyValues.put (extraKeyID, key);
			_extraKeyTitles.put (extraKeyID, key);
		}

		for (int i = 0; i < allocatableKeyCount; ++i) {
			keysToAlloc.remove (0);
		}
	}
	//endregion
}
