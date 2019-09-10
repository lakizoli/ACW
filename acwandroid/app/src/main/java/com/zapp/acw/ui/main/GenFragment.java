package com.zapp.acw.ui.main;

import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.ViewModelProviders;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;

import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import com.zapp.acw.R;
import com.zapp.acw.bll.Deck;
import com.zapp.acw.bll.Package;

import java.util.ArrayList;

public class GenFragment extends Fragment implements Toolbar.OnMenuItemClickListener {

	private GenViewModel mViewModel;

	public static GenFragment newInstance () {
		return new GenFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.gen_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);

		mViewModel = ViewModelProviders.of (this).get (GenViewModel.class);

		Bundle args = getArguments ();
		Package pack = null;
		if (args != null) {
			pack = args.getParcelable ("package");
		}

		mViewModel.init (pack);

		//Init toolbar
		FragmentActivity activity = getActivity ();
		Toolbar toolbar = activity.findViewById (R.id.toolbar);
		toolbar.inflateMenu (R.menu.gen_menu);
		toolbar.setOnMenuItemClickListener (this);

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				//...Nothing to do here...
			}
		};
		requireActivity ().getOnBackPressedDispatcher ().addCallback (this, callback);
	}

	@Override
	public boolean onMenuItemClick (MenuItem menuItem) {
		switch (menuItem.getItemId ()) {
			case R.id.action_done:
				//TODO: Navigation.findNavController (getView ()).navigate (R.id.ShowGen);
				return true;
			default:
				break;
		}
		return false;
	}
}
