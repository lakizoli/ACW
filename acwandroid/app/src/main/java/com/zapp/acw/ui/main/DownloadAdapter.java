package com.zapp.acw.ui.main;

import android.content.Context;
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
	private ArrayList<NetPackConfig.NetPackConfigItem> _packageConfigs;

	public DownloadAdapter (ArrayList<NetPackConfig.NetPackConfigItem> packageConfigs) {
		_packageConfigs = packageConfigs;
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
		NetPackConfig.NetPackConfigItem item = _packageConfigs.get (position);

		// Set item views based on your views and data model
		TextView textView = holder.languageName;
		textView.setText (item.label);
	}

	@Override
	public int getItemCount () {
		return _packageConfigs == null ? 0 : _packageConfigs.size ();
	}
}
