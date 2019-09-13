package com.zapp.acw.ui.main;

import android.content.Context;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.zapp.acw.R;
import com.zapp.acw.bll.Package;

import java.util.ArrayList;
import java.util.HashMap;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

public class ChooseCWAdapter extends RecyclerView.Adapter<ChooseCWAdapter.ViewHolder>  {
	public interface OnItemClickListener {
		void onItemClick (int position, Package pack);
		void onRandomButtonClick (int position, Package pack);
	}

	private boolean _isSubscribed;
	private ArrayList<String> _sortedPackageKeys; ///< The keys of the packages sorted by package name
	private HashMap<String, Package> _packages;
	private HashMap<String, Integer> _currentSavedCrosswordIndices; ///< The index of the currently played crossword of packages
	private HashMap<String, Integer> _filledWordCounts; ///< The filled word counts of packages
	private OnItemClickListener _onItemClickListener;

	private int _disabledPackColor = Color.argb (255, 255, 0, 0);
	private int _disabledSelectedPackColor = Color.argb (255, 255, 77,77);
	private int _normalTextColor = Color.argb (255, 33, 34, 33);
	private int _normalSubTextColor = Color.argb (255, 78, 80, 79);
	private int _selectionTextColor = Color.argb (255, 223, 194, 93);
	private int _selectionBackgroundColor = Color.argb (255, 40, 80, 80);
	private int _selectedPosition = -1;

	public ChooseCWAdapter (boolean isSubscribed, ArrayList<String> sortedPackageKeys, HashMap<String, Package> packages,
							HashMap<String, Integer> currentSavedCrosswordIndices, HashMap<String, Integer> filledWordCounts,
							OnItemClickListener onItemClickListener)
	{
		_isSubscribed = isSubscribed;
		_sortedPackageKeys = sortedPackageKeys;
		_packages = packages;
		_currentSavedCrosswordIndices = currentSavedCrosswordIndices;
		_filledWordCounts = filledWordCounts;
		_onItemClickListener = onItemClickListener;
	}

	public class ViewHolder extends RecyclerView.ViewHolder {
		public TextView packageName;
		public TextView statistics;
		public TextView randomButton;

		public ViewHolder (View itemView) {
			super (itemView);

			packageName = itemView.findViewById (R.id.cw_package_name);
			statistics = itemView.findViewById (R.id.cw_statistic);
			randomButton = itemView.findViewById (R.id.cw_random_button);
		}
	}

	@NonNull
	@Override
	public ChooseCWAdapter.ViewHolder onCreateViewHolder (@NonNull ViewGroup parent, int viewType) {
		Context context = parent.getContext ();
		LayoutInflater inflater = LayoutInflater.from (context);

		// Inflate the custom layout
		View itemView = inflater.inflate (R.layout.choose_cw_row, parent, false);

		// Return a new holder instance
		ChooseCWAdapter.ViewHolder viewHolder = new ChooseCWAdapter.ViewHolder (itemView);
		return viewHolder;
	}

	@Override
	public void onBindViewHolder (@NonNull ChooseCWAdapter.ViewHolder holder, final int position) {
		// Get the data model based on position
		final String packageKey = _sortedPackageKeys.get (position);

		// Set item views based on your views and data model
		int filledLevelCount = _currentSavedCrosswordIndices.get (packageKey);
		int filledWordCount = _filledWordCounts.get (packageKey);

//		cell.parent = self;
//		cell.packageKey = packageKey;

		final Package pack = _packages.get (packageKey);

		boolean cwEnabled = position < 1 || _isSubscribed;
		if (cwEnabled) {
			if (_selectedPosition == position) {
				holder.packageName.setTextColor (_selectionTextColor);
				holder.statistics.setTextColor (_selectionTextColor);
				holder.randomButton.setTextColor (_selectionTextColor);

				holder.itemView.setBackgroundColor (_selectionBackgroundColor);
			} else {
				holder.packageName.setTextColor (_normalTextColor);
				holder.statistics.setTextColor (_normalSubTextColor);
				holder.randomButton.setTextColor (_normalSubTextColor);

				holder.itemView.setBackgroundColor (0);
			}
		} else {
			if (_selectedPosition == position) {
				holder.packageName.setTextColor (_disabledSelectedPackColor);
				holder.statistics.setTextColor (_disabledSelectedPackColor);
				holder.randomButton.setTextColor (_disabledSelectedPackColor);

				holder.itemView.setBackgroundColor (_selectionBackgroundColor);
			} else {
				holder.packageName.setTextColor (_disabledPackColor);
				holder.statistics.setTextColor (_disabledPackColor);
				holder.randomButton.setTextColor (_disabledPackColor);

				holder.itemView.setBackgroundColor (0);
			}
		}

		String title = pack.state.overriddenPackageName;
		if (title == null || title.length () <= 0) {
			title = pack.name;
		}
		holder.packageName.setText (title);
		holder.statistics.setText (String.format ("%d of %d levels (%d of %d words) solved",
			filledLevelCount,
			pack.state.levelCount,
			pack.state.filledLevel >= pack.state.levelCount ? pack.state.wordCount : filledWordCount,
			pack.state.wordCount));

//		if (cwEnabled) {
//			[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
//		} else {
//			[cell setAccessoryType:UITableViewCellAccessoryNone];
//		}

		// Set the click listener
		holder.itemView.setOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				_selectedPosition = position;
				notifyDataSetChanged ();

				_onItemClickListener.onItemClick (position, pack);
			}
		});

		holder.randomButton.setOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				_onItemClickListener.onRandomButtonClick (position, pack);
			}
		});
	}

	@Override
	public int getItemCount () {
		return _sortedPackageKeys == null ? 0 : _sortedPackageKeys.size ();
	}
}
