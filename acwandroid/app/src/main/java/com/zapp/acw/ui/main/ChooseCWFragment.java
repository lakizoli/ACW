package com.zapp.acw.ui.main;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TimePicker;

import com.zapp.acw.R;
import com.zapp.acw.bll.Package;

import java.util.Timer;
import java.util.TimerTask;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.ItemTouchHelper;
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

		final ProgressBar progressCW = activity.findViewById (R.id.cw_progress);
		progressCW.setVisibility (View.VISIBLE);

		mViewModel.getAction ().observe (getViewLifecycleOwner (), new Observer<Integer> () {
			@Override
			public void onChanged (Integer action) {
				switch (action) {
					case RELOAD_PACKAGES_ENDED:
						progressCW.setVisibility (View.INVISIBLE);
						helpLayout.setVisibility (mViewModel.hasSomePackages () ? View.INVISIBLE : View.VISIBLE);
						rvCWs.setVisibility (mViewModel.hasSomePackages () ? View.VISIBLE : View.INVISIBLE);

						//TODO: handle isSubscribed!!!
						ChooseCWAdapter adapter = new ChooseCWAdapter (true, mViewModel.getSortedPackageKeys (), mViewModel.getPackages (),
							mViewModel.getCurrentSavedCrosswordIndices (), mViewModel.getFilledWordCounts (), new ChooseCWAdapter.OnItemClickListener () {
							@Override
							public void onItemClick (int position, Package pack) {
								//TODO: open the next cw level...
							}

							@Override
							public void onRandomButtonClick (int position, Package pack) {
								//TODO: open a random already solved cw level...
							}
						});

						rvCWs.setAdapter (adapter);
						rvCWs.setLayoutManager (new LinearLayoutManager (activity));
						ItemTouchHelper itemTouchHelper = new ItemTouchHelper (new SwipeToDeleteCallback (activity, new SwipeToDeleteCallback.OnDeleteCallback () {
							@Override
							public void onDeleteItem (int position) {
								//TODO: handle deletion of the package!!
							}
						}));
						itemTouchHelper.attachToRecyclerView (rvCWs);
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

		mViewModel.startReloadPackages ();
	}

	@Override
	public boolean onMenuItemClick (MenuItem menuItem) {
		switch (menuItem.getItemId ()) {
			case R.id.action_plus:
				final FragmentActivity activity = getActivity ();
				final ProgressBar progressCW = activity.findViewById (R.id.cw_progress);
				progressCW.setVisibility (View.VISIBLE);

				new Thread (new Runnable () {
					@Override
					public void run () {
						try {
							Thread.sleep(1000);
						} catch (InterruptedException e) {
						}

						activity.runOnUiThread (new Runnable () {
							@Override
							public void run () {
								Navigation.findNavController (getView ()).navigate (R.id.ShowDownload);
							}
						});
					}
				}).start ();
				return true;
			default:
				break;
		}
		return false;
	}
}
