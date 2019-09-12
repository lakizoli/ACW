package com.zapp.acw.ui.main;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.zapp.acw.R;
import com.zapp.acw.bll.Field;
import com.zapp.acw.bll.GeneratorInfo;

public class GenAdapter extends RecyclerView.Adapter<GenAdapter.ViewHolder> {
	public interface OnItemClickListener {
		void onItemClick (int position, Field field);
	}

	private GeneratorInfo _generatorInfo;
	private OnItemClickListener _clickListener;

	public GenAdapter (GeneratorInfo generatorInfo, OnItemClickListener clickListener) {
		_generatorInfo = generatorInfo;
		_clickListener = clickListener;
	}

	public class ViewHolder extends RecyclerView.ViewHolder {
		public TextView fieldName;

		public ViewHolder (View itemView) {
			super (itemView);

			fieldName = itemView.findViewById (R.id.field_name);
		}
	}

	@NonNull
	@Override
	public GenAdapter.ViewHolder onCreateViewHolder (@NonNull ViewGroup parent, int viewType) {
		Context context = parent.getContext ();
		LayoutInflater inflater = LayoutInflater.from (context);

		// Inflate the custom layout
		View itemView = inflater.inflate (R.layout.gen_row, parent, false);

		// Return a new holder instance
		GenAdapter.ViewHolder viewHolder = new GenAdapter.ViewHolder (itemView);
		return viewHolder;
	}

	@Override
	public void onBindViewHolder (@NonNull GenAdapter.ViewHolder holder, final int position) {
		// Get the data model based on position
		final Field item = _generatorInfo.fields.get (position);

		// Set item views based on your views and data model
		TextView textView = holder.fieldName;
		textView.setText (item.name);

		// Set the click listener
		holder.itemView.setOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				_clickListener.onItemClick (position, item);
			}
		});
	}

	@Override
	public int getItemCount () {
		return _generatorInfo != null && _generatorInfo.fields != null ? _generatorInfo.fields.size () : 0;
	}
}