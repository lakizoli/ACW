package com.zapp.acw.ui.main;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.pm.ActivityInfo;
import android.net.Uri;
import android.os.Bundle;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.Surface;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;

import com.google.android.material.tabs.TabLayout;
import com.zapp.acw.R;
import com.zapp.acw.bll.NetPackConfig;

import java.util.ArrayList;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.NavOptions;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

public class DownloadFragment extends Fragment implements TabLayout.OnTabSelectedListener {
	private DownloadViewModel mViewModel;
	private ProgressView mProgressView;
	private boolean mMoveChooseInsteadOfDismiss = false;

	public static DownloadFragment newInstance () {
		return new DownloadFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		Bundle args = getArguments ();
		if (args != null) {
			mMoveChooseInsteadOfDismiss = args.getBoolean ("MoveChooseInsteadOfDismiss");
		}

		return inflater.inflate (R.layout.download_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);

		mViewModel = ViewModelProviders.of (this).get (DownloadViewModel.class);

		final FragmentActivity activity = getActivity ();

		final ProgressBar progressDownload = activity.findViewById (R.id.download_progress);
		progressDownload.setVisibility (View.VISIBLE);

		mViewModel.getAction ().observe (getViewLifecycleOwner (), new Observer<Integer> () {
			@Override
			public void onChanged (Integer action) {
				switch (action.intValue ()) {
					case DownloadViewModel.DISMISS_VIEW:
						mProgressView.setVisibility (View.INVISIBLE);
						unlockOrientation ();
						dismissView ();
						break;
					case DownloadViewModel.SHOW_FAILED_ALERT:
						mProgressView.setVisibility (View.INVISIBLE);
						unlockOrientation ();

						AlertDialog.Builder builder = new AlertDialog.Builder (getContext ());
						builder.setCancelable (false);
						builder.setTitle (R.string.error_title);
						builder.setMessage (R.string.download_error);

						builder.setPositiveButton (R.string.ok, new DialogInterface.OnClickListener () {
							@Override
							public void onClick (DialogInterface dialog, int which) {
								dismissView ();
							}
						});

						AlertDialog alertDialog = builder.create ();
						alertDialog.show ();
						break;
					case DownloadViewModel.SHOW_GEN_VIEW:
						mProgressView.setVisibility (View.INVISIBLE);
						unlockOrientation ();

						Bundle args = new Bundle ();
						args.putParcelable ("package", mViewModel.getPackage ());
						args.putBoolean ("moveChooseInsteadOfDismiss", mMoveChooseInsteadOfDismiss);

						if (mMoveChooseInsteadOfDismiss) {
							Navigation.findNavController (getView ()).navigate (R.id.ShowGen, args);
						} else {
							NavOptions.Builder navOptionsBuilder = new NavOptions.Builder ();
							Navigation.findNavController (getView ()).navigate (R.id.ShowGen, args, navOptionsBuilder.setPopUpTo (R.id.chooseCW, false).build ());
						}
						break;
					default:
						break;
				}
			}
		});

		mViewModel.getPackageConfigs ().observe (getViewLifecycleOwner (), new Observer<ArrayList<NetPackConfig.NetPackConfigItem>> () {
			@Override
			public void onChanged (ArrayList<NetPackConfig.NetPackConfigItem> netPackConfigItems) {
				progressDownload.setVisibility (View.INVISIBLE);

				final RecyclerView rvPackages = activity.findViewById (R.id.package_list);

				DownloadAdapter adapter = new DownloadAdapter (netPackConfigItems, new DownloadAdapter.OnItemClickListener () {
					@Override
					public void onItemClick (NetPackConfig.NetPackConfigItem item) {
						//Show progrss view
						showProgressView ();

						//Disable page's controls
						rvPackages.setEnabled (false);

						TabLayout tabLayout = activity.findViewById(R.id.tab_layout);
						tabLayout.setEnabled (false);

						//Start downloading the package
						mViewModel.startDownloadPackage (activity, item);
					}
				});
				rvPackages.setAdapter(adapter);
				rvPackages.setLayoutManager(new LinearLayoutManager (activity));
			}
		});

		mViewModel.getProgress ().observe (getViewLifecycleOwner (), new Observer<Pair<Integer, String>> () {
			@Override
			public void onChanged (Pair<Integer, String> progress) {
				mProgressView.setProgress (progress.first);
				mProgressView.setLabel (progress.second);
			}
		});

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				dismissView ();
			}
		};
		activity.getOnBackPressedDispatcher ().addCallback (this, callback);

		//Init tab bar
		TabLayout tabLayout = activity.findViewById(R.id.tab_layout);
		tabLayout.addOnTabSelectedListener (this);

		switch (mViewModel.selectedTab) {
			case DownloadViewModel.TAB_FEATURED: {
				TabLayout.Tab tab = tabLayout.getTabAt (DownloadViewModel.TAB_FEATURED);
				tab.select ();
				selectTopRated ();
				break;
			}
			case DownloadViewModel.TAB_SEARCH: {
				TabLayout.Tab tab = tabLayout.getTabAt (DownloadViewModel.TAB_SEARCH);
				tab.select ();
				selectSearch ();
				break;
			}
		}

		//Init toolbar
		Toolbar toolbar = activity.findViewById (R.id.download_toolbar);
		toolbar.setNavigationIcon (R.drawable.ic_arrow_back_black_24dp);
		toolbar.setNavigationOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				dismissView ();
			}
		});

		//Init progress view
		mProgressView = new ProgressView (activity, R.id.progress_view, R.id.text_view_progress, R.id.progress_bar, R.id.button_progress);
		mProgressView.setVisibility (View.INVISIBLE);
		unlockOrientation ();

		//Init webview
		WebView webView = activity.findViewById (R.id.web_search);
		webView.setWebViewClient (new AnkiWebViewClient (this, activity, mViewModel));
		WebSettings webSettings = webView.getSettings ();
		webSettings.setJavaScriptEnabled (true);

		//Start download package list or dismiss when needed
		mViewModel.startDownloadPackageList (activity);
	}

	//region Tab selection functions
	private void selectTopRated () {
		mViewModel.selectedTab = DownloadViewModel.TAB_FEATURED;
		FragmentActivity activity = getActivity ();

		//Show table view
		WebView webView = activity.findViewById (R.id.web_search);
		webView.setVisibility (View.INVISIBLE);
		webView.loadUrl ("about:blank");

		RecyclerView tableView = activity.findViewById (R.id.package_list);
		tableView.setVisibility (View.VISIBLE);
	}

	private void selectSearch () {
		mViewModel.selectedTab = DownloadViewModel.TAB_SEARCH;
		FragmentActivity activity = getActivity ();

		//Show web view
		RecyclerView tableView = activity.findViewById (R.id.package_list);
		tableView.setVisibility (View.INVISIBLE);

		WebView webView = activity.findViewById (R.id.web_search);
		webView.setVisibility (View.VISIBLE);

		//Browse anki sheets site
		String url = "https://ankiweb.net/shared/decks/";
		webView.loadUrl (url);
	}

	@Override
	public void onTabSelected (TabLayout.Tab tab) {
		switch (tab.getPosition ()) {
			case DownloadViewModel.TAB_FEATURED:
				selectTopRated ();
				break;
			case DownloadViewModel.TAB_SEARCH:
				selectSearch ();
				break;
			default:
				break;
		}
	}

	@Override
	public void onTabUnselected (TabLayout.Tab tab) {
		//... Nothing to do here ...
	}

	@Override
	public void onTabReselected (TabLayout.Tab tab) {
		//... Nothing to do here ...
	}
	//endregion

	private void dismissView() {
		if (mMoveChooseInsteadOfDismiss) { //We came here from the main fragment
			Navigation.findNavController (getView ()).navigate (R.id.ShowChooseCW);
		} else { //We came here from the choose CW fragment upon click the plus button
			Navigation.findNavController (getView ()).navigateUp ();
		}
	}

	private void showProgressView () {
		mProgressView.setButtonText (R.string.cancel);
		mProgressView.setLabel (R.string.downloading);
		mProgressView.setProgress (0);

		mProgressView.setOnButtonPressed (new Runnable () {
			@Override
			public void run () {
				mViewModel.cancelDownload ();
			}
		});

		mProgressView.setVisibility (View.VISIBLE);

		lockOrientation ();
	}

	private void lockOrientation () {
		int orientation = getActivity ().getRequestedOrientation ();
		int rotation = ((WindowManager) getActivity ().getSystemService (Context.WINDOW_SERVICE)).getDefaultDisplay ().getRotation ();
		switch (rotation) {
			case Surface.ROTATION_0:
				orientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
				break;
			case Surface.ROTATION_90:
				orientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
				break;
			case Surface.ROTATION_180:
				orientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
				break;
			default:
			case Surface.ROTATION_270:
				orientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
				break;
		}

		getActivity ().setRequestedOrientation (orientation);
	}

	private void unlockOrientation () {
		getActivity ().setRequestedOrientation (ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
	}

	private static class AnkiWebViewClient extends WebViewClient {
		private DownloadFragment mFragment;
		private FragmentActivity mActivity;
		private DownloadViewModel mViewModel;

		public AnkiWebViewClient (DownloadFragment fragment, FragmentActivity activity, DownloadViewModel viewModel) {
			mFragment = fragment;
			mActivity = activity;
			mViewModel = viewModel;
		}

		@Override
		public boolean shouldOverrideUrlLoading (WebView view, String url) {
			//Catch package download
			Uri uri = Uri.parse (url);
			String host = uri.getHost ().toLowerCase ();
			String path = uri.getPath ().toLowerCase ();

			if (host.contains ("ankiweb.net") && path.contains ("download") && url.contains ("?")) { //Page is from ankiweb, and link is a download link
				//Show progress view
				mFragment.showProgressView ();

				//Disable page's controls
				WebView webView = mActivity.findViewById (R.id.web_search);
				webView.setEnabled (false);

				TabLayout tabLayout = mActivity.findViewById(R.id.tab_layout);
				tabLayout.setEnabled (false);

				//Start download
				mViewModel.startDownloadOfAnkiPackage (mActivity, url, true);
				return true;
			}

			return false; // Let the WebView load the page
		}
	}
}
