package com.zapp.acw.ui.main;

import android.content.DialogInterface;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.zapp.acw.FileUtils;
import com.zapp.acw.R;
import com.zapp.acw.bll.NetLogger;
import com.zapp.acw.bll.Package;
import com.zapp.acw.bll.SavedCrossword;
import com.zapp.acw.bll.SubscriptionManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Random;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.StringRes;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

public class ChooseCWFragment extends BackgroundInitFragment implements Toolbar.OnMenuItemClickListener {
	private ChooseCWViewModel mViewModel;
	private boolean mIsInProgress = false;

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
		mIsInProgress = false;

		mViewModel = ViewModelProviders.of (this).get (ChooseCWViewModel.class);

		final FragmentActivity activity = getActivity ();
		final LinearLayout helpLayout = activity.findViewById (R.id.help_layout);
		helpLayout.setVisibility (View.INVISIBLE);

		final RecyclerView rvCWs = activity.findViewById (R.id.cw_list);
		rvCWs.setVisibility (View.INVISIBLE);

		final ProgressBar progressCW = activity.findViewById (R.id.cw_progress);
		progressCW.setVisibility (View.VISIBLE);

		mViewModel.setInitEndedObserver (new BackgroundInitViewModel.InitEndedObserver () {
			@Override
			public void onInitEnded () {
				progressCW.setVisibility (View.INVISIBLE);
				helpLayout.setVisibility (mViewModel.hasSomePackages () ? View.INVISIBLE : View.VISIBLE);
				rvCWs.setVisibility (mViewModel.hasSomePackages () ? View.VISIBLE : View.INVISIBLE);

				ChooseCWAdapter adapter = new ChooseCWAdapter (mViewModel.isSubscribed (), mViewModel.getSortedPackageKeys (), mViewModel.getPackages (),
					mViewModel.getCurrentSavedCrosswordIndices (), mViewModel.getFilledWordCounts (), new ChooseCWAdapter.OnItemClickListener () {
					@Override
					public void onItemClick (final int position, Package pack) {
						boolean cwEnabled = position == 0 || mViewModel.isSubscribed ();
						if (!cwEnabled) {
							showSubscription ();
						} else {
							final FragmentActivity activity = getActivity ();
							runWithProgress (new Runnable () {
								@Override
								public void run () {
									String packageKey = mViewModel.getSortedPackageKeys ().get (position);
									int idx = mViewModel.getCurrentSavedCrosswordIndices ().get (packageKey);

									final Bundle args = buildShowCWBundle (packageKey, idx, false);
									activity.runOnUiThread (new Runnable () {
										@Override
										public void run () {
											Navigation.findNavController (getView ()).navigate (R.id.ShowCW, args);
										}
									});
								}
							});
						}
					}

					@Override
					public void onRandomButtonClick (final int position, Package pack) {
						boolean cwEnabled = position == 0 || mViewModel.isSubscribed ();
						if (!cwEnabled) {
							showSubscription ();
						} else {
							final FragmentActivity activity = getActivity ();
							runWithProgress (new Runnable () {
								@Override
								public void run () {
									String packageKey = mViewModel.getSortedPackageKeys ().get (position);
									int idx = mViewModel.getCurrentSavedCrosswordIndices ().get (packageKey);

									ArrayList<Integer> randIndices = mViewModel.getRandIndices (packageKey, idx);
									int randCount = randIndices != null ? randIndices.size () : 0;

									int randIdx = new Random ().nextInt (randCount + 1);
									randIdx = randIndices != null ? randIndices.get (randIdx) : 0;

									final Bundle args = buildShowCWBundle (packageKey, randIdx, true);
									activity.runOnUiThread (new Runnable () {
										@Override
										public void run () {
											Navigation.findNavController (getView ()).navigate (R.id.ShowCW, args);
										}
									});
								}
							});
						}
					}
				});

				rvCWs.setAdapter (adapter);
				rvCWs.setLayoutManager (new LinearLayoutManager (activity));
				ItemTouchHelper itemTouchHelper = new ItemTouchHelper (new SwipeToDeleteCallback (activity, new SwipeToDeleteCallback.OnDeleteCallback () {
					@Override
					public void onDeleteItem (final int position) {
						if (!mViewModel.isSubscribed ()) {
							showSubscriptionOnDelete (new Runnable () {
								@Override
								public void run () {
									activity.recreate ();
								}
							});
							return;
						}

						AlertDialog.Builder builder = new AlertDialog.Builder (activity);
						builder.setTitle (R.string.do_you_want_delete_cw);

						builder.setMessage (R.string.cannot_undo_this_action);

						builder.setNegativeButton (R.string.cancel, new DialogInterface.OnClickListener () {
							@Override
							public void onClick (DialogInterface dialog, int which) {
								activity.recreate ();
							}
						});
						builder.setPositiveButton (R.string.delete, new DialogInterface.OnClickListener () {
							@Override
							public void onClick (DialogInterface dialog, int which) {
								String packageKey = mViewModel.getSortedPackageKeys ().get (position);
								final Package pack = mViewModel.getPackages ().get (packageKey);
								NetLogger.logEvent ("SUIChooseCW_DeleteCW", new HashMap<String, String> () {{
									put ("package", FileUtils.getFileName (pack.path));
								}});

								if (!FileUtils.deleteRecursive (pack.path)) {
									Log.e ("ChooseCWFragment", "Cannot remove package at path: " + pack.path);
								}

								activity.recreate ();
							}
						});

						builder.show ();
					}
				}));
				itemTouchHelper.attachToRecyclerView (rvCWs);

				RefreshSubscriptionFragment ();

				//Sign end of init
				endInit ();
			}
		});

		final TextView subscribeButton = activity.findViewById (R.id.cw_subscribe_button);
		subscribeButton.setOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				if (!isInInit () && !mIsInProgress) {
					Navigation.findNavController (getView ()).navigate (R.id.ShowStore);
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

		mViewModel.startInit (new SubscriptionManager.SubscribeChangeListener () {
			@Override
			public void SubscribeChanged () {
				if (!isInInit () && !mIsInProgress) {
					RefreshSubscriptionFragment ();
				}
			}
		});

		//Show pending subscription alert
		@StringRes int pendingSubscriptionAlert = SubscriptionManager.sharedInstance ().popPendingSubscriptionAlert ();
		if (pendingSubscriptionAlert != 0) {
			SubscriptionManager.sharedInstance ().showSubscriptionAlert (activity, getView (), pendingSubscriptionAlert);
		}
	}

	@Override
	public boolean onMenuItemClick (MenuItem menuItem) {
		switch (menuItem.getItemId ()) {
			case R.id.action_plus:
				final FragmentActivity activity = getActivity ();
				runWithProgress (new Runnable () {
					@Override
					public void run () {
						activity.runOnUiThread (new Runnable () {
							@Override
							public void run () {
								Navigation.findNavController (getView ()).navigate (R.id.ShowDownload);
								unlockOrientation ();
							}
						});
					}
				});
				return true;
			default:
				break;
		}
		return false;
	}

	private void runWithProgress (final Runnable block) {
		if (mIsInProgress || isInInit ()) {
			return;
		}
		mIsInProgress = true;
		lockOrientation ();

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

				block.run ();
			}
		}).start ();
	}

	private void showSubscription () {
		SubscriptionManager.sharedInstance ().showSubscriptionAlert (getActivity (), getView (), R.string.subscribe_take_to_store);
	}

	private void showSubscriptionOnDelete (Runnable onNo) {
		SubscriptionManager.sharedInstance ().showSubscriptionAlert (getActivity (), getView (), R.string.subscribe_on_delete_warning, onNo, null);
	}

	private Bundle buildShowCWBundle (String packageKey, int crosswordIndex, boolean isRandomGame) {
		Bundle bundle = new Bundle ();

		Package pack = mViewModel.getPackages ().get (packageKey);
		ArrayList<SavedCrossword> cws = mViewModel.getSavedCrosswords ().get (packageKey);

		bundle.putParcelable ("package", pack);
		bundle.putParcelable ("savedCrossword", cws.get (crosswordIndex));
		bundle.putInt ("currentCrosswordIndex", crosswordIndex);
		bundle.putParcelableArrayList ("allSavedCrossword", cws);
		bundle.putBoolean ("isMultiLevelGame", !isRandomGame);

		return bundle;
	}

	private void RefreshSubscriptionFragment () {
		FragmentActivity activity = getActivity ();
		if (activity != null) {
			LinearLayout linearLayout = activity.findViewById (R.id.cw_subscriber_warning);
			if (linearLayout != null) {
				boolean isSubscribed = SubscriptionManager.sharedInstance ().isSubscribed ();
				linearLayout.setVisibility (isSubscribed ? View.INVISIBLE : View.VISIBLE);
			}
		}
	}
}
