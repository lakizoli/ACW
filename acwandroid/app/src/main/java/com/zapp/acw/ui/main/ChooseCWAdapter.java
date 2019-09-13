package com.zapp.acw.ui.main;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.zapp.acw.R;

import java.util.ArrayList;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

public class ChooseCWAdapter extends RecyclerView.Adapter<ChooseCWAdapter.ViewHolder>  {
	private ArrayList<String> _sortedPackageKeys; ///< The keys of the packages sorted by package name

	public ChooseCWAdapter (ArrayList<String> sortedPackageKeys) {
		_sortedPackageKeys = sortedPackageKeys;
	}

	public class ViewHolder extends RecyclerView.ViewHolder {
		public TextView title;

		public ViewHolder (View itemView) {
			super (itemView);

			title = itemView.findViewById (R.id.cw_title);
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
	public void onBindViewHolder (@NonNull ChooseCWAdapter.ViewHolder holder, int position) {
		// Get the data model based on position
		final String item = _sortedPackageKeys.get (position);

		// Set item views based on your views and data model
		TextView textView = holder.title;
		textView.setText (item);

//		// Set the click listener
//		holder.itemView.setOnClickListener (new View.OnClickListener () {
//			@Override
//			public void onClick (View v) {
//				_clickListener.onItemClick (item);
//			}
//		});
	}

	@Override
	public int getItemCount () {
		return _sortedPackageKeys == null ? 0 : _sortedPackageKeys.size ();
	}
}
