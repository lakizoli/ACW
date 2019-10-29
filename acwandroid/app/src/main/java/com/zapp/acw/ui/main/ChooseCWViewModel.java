package com.zapp.acw.ui.main;

import android.app.Activity;

import com.zapp.acw.FileUtils;
import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.PackageManager;
import com.zapp.acw.bll.SavedCrossword;
import com.zapp.acw.bll.SubscriptionManager;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;

public class ChooseCWViewModel extends BackgroundInitViewModel {
	private boolean _isSubscribed = false;
	private ArrayList<String> _sortedPackageKeys; ///< The keys of the packages sorted by package name
	private HashMap<String, Package> _packages;
	private HashMap<String, Integer> _currentSavedCrosswordIndices; ///< The index of the currently played crossword of packages
	private HashMap<String, Integer> _filledWordCounts; ///< The filled word counts of packages
	private HashMap<String, ArrayList<SavedCrossword>> _savedCrosswords; ///< All of the generated crosswords of packages

	public boolean isSubscribed () {
		return _isSubscribed;
	}
	public ArrayList<String> getSortedPackageKeys () {
		return _sortedPackageKeys;
	}
	public HashMap<String, Package> getPackages () {
		return _packages;
	}
	public HashMap<String, Integer> getCurrentSavedCrosswordIndices () {
		return _currentSavedCrosswordIndices;
	}
	public HashMap<String, Integer> getFilledWordCounts () {
		return _filledWordCounts;
	}
	public HashMap<String, ArrayList<SavedCrossword>> getSavedCrosswords () {
		return _savedCrosswords;
	}

	public void startInit (final Activity activity, final SubscriptionManager.SubscribeChangeListener subscribeChangeListener) {
		startInit (new InitListener () {
			@Override
			public void initInBackground () {
				SubscriptionManager subscriptionManager = SubscriptionManager.sharedInstance ();
				subscriptionManager.connectBilling (activity, subscribeChangeListener);
				_isSubscribed = subscriptionManager.isSubscribed ();

				PackageManager man = PackageManager.sharedInstance ();
				ArrayList<Package> packs = man.collectPackages ();
				_savedCrosswords = man.collectSavedCrosswords ();

				_sortedPackageKeys = new ArrayList<> ();
				_packages = new HashMap<> ();
				for (Package obj : packs) {
					String packageKey = FileUtils.getFileName (obj.path);
					ArrayList<SavedCrossword> cws = _savedCrosswords.get (packageKey);
					if (cws != null && cws.size () > 0) {
						_sortedPackageKeys.add (packageKey);
						_packages.put (packageKey, obj);
					}
				}

				Collections.sort (_sortedPackageKeys, new Comparator<String> () {
					@Override
					public int compare (String obj1, String obj2) {
						Package pack1 = _packages.get (obj1);
						Package pack2 = _packages.get (obj2);

						String name1 = pack1 != null && pack1.state != null ? pack1.state.overriddenPackageName : null;
						if (name1 == null || name1.length () <= 0) {
							name1 = pack1.name;
						}

						String name2 = pack2 != null && pack2.state != null ? pack2.state.overriddenPackageName : null;
						if (name2 == null || name2.length () <= 0) {
							name2 = pack2.name;
						}

						return name1.compareTo (name2);
					}
				});

				_currentSavedCrosswordIndices = new HashMap<> ();
				_filledWordCounts = new HashMap<> ();
				for (String packageKey : _sortedPackageKeys) {
					Package pack = _packages.get (packageKey);
					ArrayList<SavedCrossword> cws = _savedCrosswords.get (packageKey);

					int currentIdx = -1;
					for (int idx = 0, iEnd = cws != null ? cws.size () : 0; idx < iEnd; ++idx) {
						SavedCrossword cw = cws.get (idx);
						if (cw.name != null && pack.state != null && pack.state.crosswordName != null && cw.name.compareTo (pack.state.crosswordName) == 0) {
							currentIdx = idx;
							break;
						}
					}
					if (currentIdx < 0) {
						currentIdx = 0;
					}

					Integer curCWIdx;
					if (pack.state != null && pack.state.filledLevel >= pack.state.levelCount) {
						curCWIdx = currentIdx + 1;
					} else {
						curCWIdx = currentIdx;
					}

					_currentSavedCrosswordIndices.put (packageKey, curCWIdx);

					int sumWordCount = 0;
					for (int idx = 0, iEnd = cws != null ? cws.size () : 0; idx < iEnd; ++idx) {
						SavedCrossword obj = cws.get (idx);
						if (idx == currentIdx) {
							break;
						}

						sumWordCount += obj.words != null ? obj.words.size () : 0;
					}

					_filledWordCounts.put (packageKey, sumWordCount);
				}
			}
		});
	}

	public boolean hasSomePackages () {
		return _sortedPackageKeys != null && _sortedPackageKeys.size () > 0;
	}

	public ArrayList<Integer> getRandIndices (String packageKey, int idx) {
		PackageManager man = PackageManager.sharedInstance ();
		return man.collectMinimalStatCountCWIndices (packageKey, _savedCrosswords, idx);
	}
}
