package com.zapp.acw.ui.main;

import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;
import android.widget.ScrollView;

import com.zapp.acw.R;
import com.zapp.acw.bll.SubscriptionManager;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.lifecycle.ViewModelProviders;
import androidx.navigation.Navigation;

public class StoreFragment extends Fragment {

	private StoreViewModel mViewModel;
	private boolean mIsInInnerDocument;
	private boolean mStoreEnabled;

	public static StoreFragment newInstance () {
		return new StoreFragment ();
	}

	@Override
	public View onCreateView (@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
							  @Nullable Bundle savedInstanceState) {
		return inflater.inflate (R.layout.store_fragment, container, false);
	}

	@Override
	public void onActivityCreated (@Nullable Bundle savedInstanceState) {
		super.onActivityCreated (savedInstanceState);

		mViewModel = ViewModelProviders.of (this).get (StoreViewModel.class);
		mIsInInnerDocument = false;
		enableStore (false);

		final FragmentActivity activity = getActivity ();

		final Toolbar toolbar = activity.findViewById (R.id.store_toolbar);
		toolbar.setNavigationIcon (R.drawable.ic_arrow_back_black_24dp);
		toolbar.setNavigationOnClickListener (new View.OnClickListener () {
			@Override
			public void onClick (View v) {
				backButtonPressed ();
			}
		});

		OnBackPressedCallback callback = new OnBackPressedCallback (true /* enabled by default */) {
			@Override
			public void handleOnBackPressed () {
				backButtonPressed ();
			}
		};
		requireActivity ().getOnBackPressedDispatcher ().addCallback (this, callback);

		mViewModel.setInitEndedObserver (new BackgroundInitViewModel.InitEndedObserver () {
			@Override
			public void onInitEnded () {
				navigateToStore ();
				enableStore (true);
			}
		});

		mViewModel.startInit (activity);
	}

	private void backButtonPressed () {
		if (mStoreEnabled) {
			if (mIsInInnerDocument) { //Navigate back to the store
				navigateToStore ();
			} else { //dismiss
				Navigation.findNavController (getView ()).navigateUp ();
			}
		}
	}

	private void navigateToStore () {
		mIsInInnerDocument = false;

		FragmentActivity activity = getActivity ();

		final Toolbar toolbar = activity.findViewById (R.id.store_toolbar);
		toolbar.setTitle (R.string.store);

		ScrollView scrollView = activity.findViewById (R.id.store_scroll);
		final WebView webView = new WebView (activity);

		scrollView.removeAllViews ();
		scrollView.addView (webView, 0, new ViewGroup.LayoutParams (ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

		WebSettings webSettings = webView.getSettings ();
		webSettings.setJavaScriptEnabled (true);

		webView.loadDataWithBaseURL ("file:///android_asset/",
			mViewModel.getConsiderationsHTML (),
			"text/html",
			"UTF-8",
			"about:blank");

		webView.setWebViewClient (new WebViewClient () {
			@Override
			public boolean shouldOverrideUrlLoading (WebView view, String url) {
				Uri uri = Uri.parse (url);
				String host = uri.getHost ();
				String path = uri.getPath ();

				if (host.startsWith ("ankidoc.com")) {
					String doc = null;
					if (path.endsWith ("privacy_policy")) {
						toolbar.setTitle (R.string.privacy_policy);
						doc = mViewModel.getPrivacyPolicyHTML ();
					} else if (path.endsWith ("terms_of_use")) {
						toolbar.setTitle (R.string.terms_of_use);
						doc = mViewModel.getTermsOfUseHTML ();
					}

					if (doc != null) {
						mIsInInnerDocument = true;

						webView.loadDataWithBaseURL ("file:///android_asset/",
							doc,
							"text/html",
							"UTF-8",
							"about:blank");
					}

					return true;
				} else if (host.startsWith ("ankibuy.com")) {
					if (path.endsWith ("monthly")) {
						enableStore (false);

						SubscriptionManager man = SubscriptionManager.sharedInstance ();
						man.buyProduct (man.getSubscribedProductForMonth ());
					} else if (path.endsWith ("yearly")) {
						enableStore (false);

						SubscriptionManager man = SubscriptionManager.sharedInstance ();
						man.buyProduct (man.getSubscribedProductForYear ());
					}

					return true;
				}

				return true;
			}
		});
	}

	private void enableStore (boolean enabled) {
		FragmentActivity activity = getActivity ();
		ProgressBar progressBar = activity.findViewById (R.id.store_progress);

		if (enabled) {
			mStoreEnabled = true;
			progressBar.setVisibility (View.INVISIBLE);
		} else {
			mStoreEnabled = false;
			progressBar.setVisibility (View.VISIBLE);
		}
	}
}
