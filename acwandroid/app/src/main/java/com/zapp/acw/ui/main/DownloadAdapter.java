package com.zapp.acw.ui.main;

import android.content.Context;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.zapp.acw.R;
import com.zapp.acw.bll.NetPackConfig;

import java.util.ArrayList;

public class DownloadAdapter extends RecyclerView.Adapter<DownloadAdapter.ViewHolder> {
	public interface OnItemClickListener {
		void onItemClick(NetPackConfig.NetPackConfigItem item);
	}

	private ArrayList<NetPackConfig.NetPackConfigItem> _packageConfigs;
	private OnItemClickListener _clickListener;

	public DownloadAdapter (ArrayList<NetPackConfig.NetPackConfigItem> packageConfigs, OnItemClickListener clickListener) {
		_packageConfigs = packageConfigs;
		_clickListener = clickListener;
	}

	public class ViewHolder extends RecyclerView.ViewHolder {
		public TextView languageName;

		public ViewHolder (View itemView) {
			super (itemView);

			languageName = itemView.findViewById (R.id.language_name);
		}
	}

	@NonNull
	@Override
	public ViewHolder onCreateViewHolder (@NonNull ViewGroup parent, int viewType) {
		Context context = parent.getContext ();
		LayoutInflater inflater = LayoutInflater.from (context);

		// Inflate the custom layout
		View itemView = inflater.inflate (R.layout.download_row, parent, false);

		// Return a new holder instance
		ViewHolder viewHolder = new ViewHolder (itemView);
		return viewHolder;
	}

	@Override
	public void onBindViewHolder (@NonNull ViewHolder holder, int position) {
		// Get the data model based on position
		final NetPackConfig.NetPackConfigItem item = _packageConfigs.get (position);

		// Set item views based on your views and data model
		TextView textView = holder.languageName;
		textView.setText (item.label);

		//Add border to cell
		View border = holder.itemView.findViewById (R.id.border_view);
		if (position % 2 == 1) { //Double border
			border.setBackgroundColor (Color.BLACK);
		} else { //Normal color
			border.setBackgroundColor (0x88AAAAAA);
		}

		// Set the click listener
		holder.itemView.setOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				_clickListener.onItemClick (item);
			}
		});
	}

	@Override
	public int getItemCount () {
		return _packageConfigs == null ? 0 : _packageConfigs.size ();
	}
}
