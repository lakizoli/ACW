package com.zapp.acw.ui.main;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import com.zapp.acw.R;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.Navigation;

import static com.zapp.acw.ui.main.ChooseCWViewModel.RELOAD_PACKAGES_ENDED;

public class ChooseCWFragment extends Fragment implements Toolbar.OnMenuItemClickListener {

	private ChooseCWViewModel mViewModel;

	public static ChooseCWFragment newInstance () {
		return new ChooseCWFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.choose_cw_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);

		mViewModel = ViewModelProviders.of (this).get (ChooseCWViewModel.class);

		mViewModel.getAction ().observe (getViewLifecycleOwner (), new Observer<Integer> () {
			@Override
			public void onChanged (Integer action) {
				switch (action) {
					case RELOAD_PACKAGES_ENDED:
						break;
					default:
						break;
				}
			}
		});

		//Init toolbar
		FragmentActivity activity = getActivity ();
		Toolbar toolbar = activity.findViewById (R.id.cw_toolbar);
		toolbar.inflateMenu (R.menu.choosecw_menu);
		toolbar.setOnMenuItemClickListener (this);

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				//...Nothing to do here...
			}
		};
		requireActivity ().getOnBackPressedDispatcher ().addCallback (this, callback);

		mViewModel.startReloadPackages ();;
	}

	@Override
	public boolean onMenuItemClick (MenuItem menuItem) {
		switch (menuItem.getItemId ()) {
			case R.id.action_plus:
				Navigation.findNavController (getView ()).navigate (R.id.ShowDownload);
				return true;
			default:
				break;
		}
		return false;
	}
}
