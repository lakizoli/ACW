package com.zapp.acw.ui.main;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.zapp.acw.R;

public class ChooseCWAdapter extends RecyclerView.Adapter<ChooseCWAdapter.ViewHolder>  {

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
//		// Get the data model based on position
//		final NetPackConfig.NetPackConfigItem item = _packageConfigs.get (position);
//
//		// Set item views based on your views and data model
//		TextView textView = holder.languageName;
//		textView.setText (item.label);
//
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
//		return _packageConfigs == null ? 0 : _packageConfigs.size ();
		return 0;
	}
}
