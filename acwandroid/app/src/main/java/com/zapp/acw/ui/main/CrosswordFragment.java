package com.zapp.acw.ui.main;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TableLayout;
import android.widget.TableRow;

import com.zapp.acw.R;
import com.zapp.acw.bll.SavedCrossword;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.Navigation;

public class CrosswordFragment extends Fragment implements Toolbar.OnMenuItemClickListener {

	private CrosswordViewModel mViewModel;

	public static CrosswordFragment newInstance () {
		return new CrosswordFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.crossword_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);
		mViewModel = ViewModelProviders.of (this).get (CrosswordViewModel.class);

		final FragmentActivity activity = getActivity ();

		//Init toolbar
		Toolbar toolbar = activity.findViewById (R.id.cwview_toolbar);
		toolbar.inflateMenu (R.menu.cwview_menu);
		toolbar.setOnMenuItemClickListener (this);
		toolbar.setNavigationIcon (R.drawable.ic_arrow_back_black_24dp);
		toolbar.setNavigationOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				Navigation.findNavController (getView ()).navigateUp ();
			}
		});

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				Navigation.findNavController (getView ()).navigateUp ();
			}
		};
		requireActivity ().getOnBackPressedDispatcher ().addCallback (this, callback);

		//Init view model
		mViewModel.init (getArguments ());

		//Build crossword table
		buildCrosswordTable (activity);
	}

	@Override
	public boolean onMenuItemClick (MenuItem item) {
		switch (item.getItemId ()) {
			case R.id.cwview_reset:
				return true;
			case R.id.cwview_hint:
				return true;
			default:
				break;
		}
		return false;
	}

	private void buildCrosswordTable (FragmentActivity activity) {
		TableLayout table = activity.findViewById (R.id.cw_table);

		final float scale = getContext().getResources().getDisplayMetrics().density;
		int pixels = Math.round (50.0f * scale + 0.5f);

		SavedCrossword savedCrossword = mViewModel.getSavedCrossword ();
		for (int row = 0; row < savedCrossword.height;++row) {
			TableRow tableRow = new TableRow (activity);
			table.addView (tableRow);

			tableRow.setLayoutParams (new LinearLayout.LayoutParams (ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));

			for (int col = 0; col < savedCrossword.width;++col) {
				View cell = new View (activity);
				tableRow.addView (cell);

				cell.requestLayout ();

				cell.getLayoutParams ().width = pixels;
				cell.getLayoutParams ().height = pixels;
				cell.setBackgroundColor ((col % 2 == 0 && row % 2 == 0) || (col % 2 == 1 && row % 2 == 1) ? 0xFFAA0000 : 0xFF00AA00);
			}
		}
	}
}
