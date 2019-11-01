package com.zapp.acw.ui.main;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.zapp.acw.R;
import com.zapp.acw.bll.Field;
import com.zapp.acw.bll.GeneratorInfo;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

public class GenAdapter extends RecyclerView.Adapter<GenAdapter.ViewHolder> {
	public interface OnItemClickListener {
		void onItemClick (int position, Field field);
	}

	public interface OnInitialSelectionListener {
		void onInitialSelection (int position, Field field);
	}

	private GeneratorInfo _generatorInfo;
	private OnItemClickListener _clickListener;
	private int _selectedPosition = -1;

	public GenAdapter (GeneratorInfo generatorInfo, int initialSelection, OnItemClickListener clickListener, OnInitialSelectionListener initialSelectionListener) {
		_generatorInfo = generatorInfo;
		_clickListener = clickListener;
		if (getItemCount () > 0) {
			_selectedPosition = initialSelection < 0 ? 0 : initialSelection;
			Field item = _generatorInfo.fields.get (_selectedPosition);
			initialSelectionListener.onInitialSelection (_selectedPosition, item);
		}
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
	public void onBindViewHolder (@NonNull final GenAdapter.ViewHolder holder, final int position) {
		// Get the data model based on position
		final Field item = _generatorInfo.fields.get (position);

		// Set item views based on your views and data model
		TextView textView = holder.fieldName;
		textView.setText (item.name);

		Resources res = textView.getResources ();
		if (position == _selectedPosition) {
			textView.setTextColor (res.getColor (R.color.colorYellowText));
			textView.setBackgroundColor (res.getColor (R.color.colorGreenBack));
		} else {
			textView.setTextColor (Color.BLACK);
			textView.setBackgroundColor (res.getColor (R.color.blueBackground));
		}

		// Set the click listener
		holder.itemView.setOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				_selectedPosition = position;
				notifyDataSetChanged ();

				_clickListener.onItemClick (position, item);
			}
		});
	}

	@Override
	public int getItemCount () {
		return _generatorInfo != null && _generatorInfo.fields != null ? _generatorInfo.fields.size () : 0;
	}
}