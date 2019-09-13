package com.zapp.acw.ui.main;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.view.View;
import android.widget.Adapter;

import com.zapp.acw.R;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

public class SwipeToDeleteCallback extends ItemTouchHelper.SimpleCallback {
	public interface OnDeleteCallback {
		void onDeleteItem (int position);
	}

	private Drawable _icon;
	private final ColorDrawable _background;
	private OnDeleteCallback _deleteCallback;

	public SwipeToDeleteCallback (Context context, OnDeleteCallback deleteCallback) {
		super (0, ItemTouchHelper.LEFT);
		_icon = ContextCompat.getDrawable (context, R.drawable.ic_delete_black_24dp);
		_background = new ColorDrawable (Color.RED);
		_deleteCallback = deleteCallback;
	}

	@Override
	public boolean onMove (@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder, @NonNull RecyclerView.ViewHolder target) {
		return false;
	}

	@Override
	public void onSwiped (@NonNull RecyclerView.ViewHolder viewHolder, int direction) {
		int position = viewHolder.getAdapterPosition ();
		_deleteCallback.onDeleteItem (position);
	}

	@Override
	public void onChildDraw (Canvas canvas, RecyclerView recyclerView, RecyclerView.ViewHolder viewHolder, float dX, float dY,
							 int actionState, boolean isCurrentlyActive)
	{
		super.onChildDraw (canvas, recyclerView, viewHolder, dX, dY, actionState, isCurrentlyActive);

		View itemView = viewHolder.itemView;
		int backgroundCornerOffset = 20;

		if (dX > 0) { // Swiping to the right
			_background.setBounds (itemView.getLeft (), itemView.getTop (),
				itemView.getLeft () + ((int) dX) + backgroundCornerOffset, itemView.getBottom ());
		} else if (dX < 0) { // Swiping to the left
			_background.setBounds (itemView.getRight () + ((int) dX) - backgroundCornerOffset,
				itemView.getTop (), itemView.getRight (), itemView.getBottom ());
		} else { // view is unSwiped
			_background.setBounds (0, 0, 0, 0);
		}
		_background.draw (canvas);

		int viewHeight = itemView.getBottom () - itemView.getTop ();
		int border = (int) (0.15f * viewHeight);
		_icon.setBounds (itemView.getRight () - viewHeight + 2 * border - backgroundCornerOffset,
			itemView.getTop () + border, itemView.getRight (), itemView.getBottom () - border);
		_icon.draw (canvas);
	}
}
