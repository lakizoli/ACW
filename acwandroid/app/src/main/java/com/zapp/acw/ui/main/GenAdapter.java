package com.zapp.acw.ui.main;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.zapp.acw.R;
import com.zapp.acw.bll.Deck;
import com.zapp.acw.bll.Field;

import java.util.ArrayList;

public class GenAdapter extends RecyclerView.Adapter<GenAdapter.ViewHolder> {
	private ArrayList<Deck> _decks;

	public GenAdapter (ArrayList<Deck> decks) {
		_decks = decks;
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
	public void onBindViewHolder (@NonNull GenAdapter.ViewHolder holder, int position) {
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
		return _decks == null ? 0 : _decks.size ();
	}

	private String getFieldValue (int row) {
		String fieldValue = "";

//		ArrayList<Field> fields = [_generatorInfo fields];
//		if (row < [fields count]) {
//			Field *field = [fields objectAtIndex:row];
//			NSArray<Card*> *cards = [_generatorInfo cards];
//
//			if ([cards count] > 0) {
//				Card *card = [cards objectAtIndex:0];
//				if ([field idx] < [[card fieldValues] count]) {
//					fieldValue = [[card fieldValues] objectAtIndex:[field idx]];
//				}
//			}
//		}

		return fieldValue;
	}

}