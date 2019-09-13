package com.zapp.acw.ui.main;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;

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
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

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

		final FragmentActivity activity = getActivity ();
		final LinearLayout helpLayout = activity.findViewById (R.id.help_layout);
		helpLayout.setVisibility (View.INVISIBLE);

		final RecyclerView rvCWs = activity.findViewById (R.id.cw_list);
		rvCWs.setVisibility (View.INVISIBLE);

		mViewModel.getAction ().observe (getViewLifecycleOwner (), new Observer<Integer> () {
			@Override
			public void onChanged (Integer action) {
				switch (action) {
					case RELOAD_PACKAGES_ENDED:
						helpLayout.setVisibility (mViewModel.hasSomePackages () ? View.INVISIBLE : View.VISIBLE);
						rvCWs.setVisibility (mViewModel.hasSomePackages () ? View.VISIBLE : View.INVISIBLE);

						ChooseCWAdapter adapter = new ChooseCWAdapter (mViewModel.getSortedPackageKeys ());
//						DownloadAdapter adapter = new DownloadAdapter (netPackConfigItems, new DownloadAdapter.OnItemClickListener () {
//							@Override
//							public void onItemClick (NetPackConfig.NetPackConfigItem item) {
//								//Show progrss view
//								showProgressView ();
//
//								//Disable page's controls
//								rvPackages.setEnabled (false);
//
//								TabLayout tabLayout = activity.findViewById(R.id.tab_layout);
//								tabLayout.setEnabled (false);
//
//								//Start downloading the package
//								mViewModel.startDownloadPackage (activity, item);
//							}
//						});

						rvCWs.setAdapter(adapter);
						rvCWs.setLayoutManager(new LinearLayoutManager (activity));
						break;
					default:
						break;
				}
			}
		});

		//Init toolbar
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
