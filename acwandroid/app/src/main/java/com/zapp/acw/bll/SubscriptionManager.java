package com.zapp.acw.bll;

import android.app.Activity;
import android.content.Context;
import android.content.DialogInterface;
import android.view.View;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.SkuDetails;
import com.android.billingclient.api.SkuDetailsParams;
import com.android.billingclient.api.SkuDetailsResponseListener;
import com.zapp.acw.BuildConfig;
import com.zapp.acw.FileUtils;
import com.zapp.acw.R;

import java.io.File;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.navigation.Navigation;

public final class SubscriptionManager implements PurchasesUpdatedListener {
	// Testing in app purchase (only success case may be tested!)
	private final boolean TEST_PURCHASE = BuildConfig.TEST_PURCHASE;

	//region Singleton construction
	private static SubscriptionManager _instance = new SubscriptionManager ();

	private SubscriptionManager () {
	}

	public static SubscriptionManager sharedInstance () {
		return _instance;
	}
	//endregion

	//region Billing
	private static final String MONTHLY_SUBS_PRODUCTID = "com.zapp.acw.monthlysubscription";
	private static final String YEARLY_SUBS_PRODUCTID = "com.zapp.acw.yearlysubscription";

	private boolean _isConnectBillingRunning = false;
	private boolean _isBillingConnected = false;
	private BillingClient _billingClient;
	private Timer _billingReconnectTimer;
	private List<SkuDetails> _products;
	private ActivityProvider _activityProvider;
	private SubscribeChangeListener _subscribeChangeListener;

	public interface ActivityProvider {
		Activity getActivity ();
	}

	public interface SubscribeChangeListener {
		void SubscribeChanged ();
	}

	public void setActivityProvider (ActivityProvider activityProvider) {
		_activityProvider = activityProvider;
	}

	public void connectBilling (SubscribeChangeListener subscribeChangeListener) {
		//Check multiple call of connect
		if (_isConnectBillingRunning || _isBillingConnected) {
			return;
		}
		_isConnectBillingRunning = true;
		_isBillingConnected = false;

		//Connect billing
		_subscribeChangeListener = subscribeChangeListener;

		if (TEST_PURCHASE) { //In test cases after start remove the purchase file
			deletePurchase ();
		}

		if (_billingClient == null) {
			SubscriptionManager man = SubscriptionManager.sharedInstance ();
			Activity activity = _activityProvider.getActivity ();
			_billingClient = BillingClient.newBuilder (activity)
				.enablePendingPurchases ()
				.setListener (man)
				.build ();
		}
		_billingClient.startConnection (new BillingClientStateListener () {
			@Override
			public void onBillingSetupFinished (BillingResult billingResult) {
				if (billingResult.getResponseCode () == BillingClient.BillingResponseCode.OK) {
					_isConnectBillingRunning = false;
					_isBillingConnected = true;

					//Query products
					_products = null;

					ArrayList<String> productIDs = new ArrayList<String> () {{
						add (MONTHLY_SUBS_PRODUCTID);
						add (YEARLY_SUBS_PRODUCTID);
					}};

					SkuDetailsParams.Builder params = SkuDetailsParams.newBuilder ();
					params.setSkusList (productIDs).setType (BillingClient.SkuType.SUBS);
					_billingClient.querySkuDetailsAsync (params.build (), new SkuDetailsResponseListener () {
						@Override
						public void onSkuDetailsResponse (BillingResult billingResult, List<SkuDetails> skuDetailsList) {
							if (billingResult.getResponseCode () == BillingClient.BillingResponseCode.OK && skuDetailsList != null) {
								_products = skuDetailsList;
							}
						}
					});

					//Query purchases
					queryPurchases ();
				} else { //Something wrong with billing
					reconnectAfterDelay (20000);
				}
			}

			@Override
			public void onBillingServiceDisconnected () {
				// Try to restart the connection on the next request to
				// Google Play by calling the startConnection() method.

				reconnectAfterDelay (20000);
			}
		});
	}

	private void reconnectAfterDelay (int delay) {
		_isConnectBillingRunning = false;
		_isBillingConnected = false;

		if (_billingReconnectTimer != null) {
			_billingReconnectTimer.cancel ();
			_billingReconnectTimer.purge ();
			_billingReconnectTimer = null;
		}

		_billingReconnectTimer = new Timer ();
		_billingReconnectTimer.schedule (new TimerTask () {
			@Override
			public void run () {
				connectBilling (_subscribeChangeListener);
			}
		}, delay);
	}

	public void queryPurchases () {
		if (!_isBillingConnected) {
			return;
		}

		Purchase.PurchasesResult purchasesResult = _billingClient.queryPurchases (BillingClient.SkuType.SUBS);
		if (purchasesResult.getBillingResult ().getResponseCode () == BillingClient.BillingResponseCode.OK) {
			List<Purchase> purchases = purchasesResult.getPurchasesList ();
			if (purchases != null) {
				for (Purchase purchase : purchases) {
					handlePurchase (purchase);
				}
			}
		}
	}

	public SkuDetails getSubscribedProductForMonth () {
		return getSubscribedProductWithID (MONTHLY_SUBS_PRODUCTID);
	}

	public SkuDetails getSubscribedProductForYear () {
		return getSubscribedProductWithID (YEARLY_SUBS_PRODUCTID);
	}

	public void buyProduct (final SkuDetails product) {
		if (!_isBillingConnected) {
			return;
		}

		if (product == null) {
			NetLogger.logEvent ("Subscription_Buy_ProductNotFound");

			showOKAlert ("Product not available!", "Subscription error!");
			return;
		}

		////////////////////////////////////////////
		// Testing purchase
		if (TEST_PURCHASE) {
			String purchaseJson = "{\"productId\" : \"%s\", \"purchaseState\" : 1," +
				" \"purchaseTime\" : \"%d\", \"acknowledged\" : \"true\"," +
				" \"token\" : \"testToken\", \"purchaseToken\" : \"testPurchaseToken\"," +
				" \"orderId\" : \"testOrderId\"}";

			Purchase purchase = null;
			if (product.getSku ().equals (MONTHLY_SUBS_PRODUCTID)) {
				try {
					purchase = new Purchase (String.format (purchaseJson, MONTHLY_SUBS_PRODUCTID, Calendar.getInstance ().getTimeInMillis ()), "fakeSignature");
				} catch (Exception ex) {
				}
			} else if (product.getSku ().equals (YEARLY_SUBS_PRODUCTID)) {
				try {
					purchase = new Purchase (String.format (purchaseJson, YEARLY_SUBS_PRODUCTID, Calendar.getInstance ().getTimeInMillis ()), "fakeSignature");
				} catch (Exception ex) {
				}
			}

			if (purchase != null) {
				handlePurchase (purchase);
			}

			return;
		}

		////////////////////////////////////////////
		// Real purchase flow
		BillingResult featureRes = _billingClient.isFeatureSupported (BillingClient.FeatureType.SUBSCRIPTIONS);
		if (featureRes.getResponseCode () != BillingClient.BillingResponseCode.OK) {
			NetLogger.logEvent ("Subscription_Buy_NotSupported", new HashMap<String, String> () {{
				put ("productIdentifier", product.getSku ());
			}});

			showOKAlert ("Subscriptions are not available on this device!", "Subscription error!");
			return;
		}

		NetLogger.logEvent ("Subscription_Buy", new HashMap<String, String> () {{
			put ("productIdentifier", product.getSku ());
		}});

		Activity activity = _activityProvider.getActivity ();
		BillingFlowParams flowParams = BillingFlowParams.newBuilder ()
			.setSkuDetails (product)
			.build ();
		final BillingResult billingFlowResult = _billingClient.launchBillingFlow (activity, flowParams);
		if (billingFlowResult.getResponseCode () != BillingClient.BillingResponseCode.OK) {
			NetLogger.logEvent ("Subscription_Buy_Failure", new HashMap<String, String> () {{
				put ("productIdentifier", product.getSku ());
				put ("error", billingFlowResult.getDebugMessage ());
			}});

			showOKAlert ("Cannot start billing flow!", "Subscription error!");
		}
	}

	private SkuDetails getSubscribedProductWithID (String productID) {
		////////////////////////////////////////////
		// Testing purchase
		if (TEST_PURCHASE) {
			String skuJson = "{\"productId\" : \"" + productID + "\", \"price\" : \"%s\", \"price_currency_code\" : \"USD\"}";

			if (productID.equals (MONTHLY_SUBS_PRODUCTID)) {
				try {
					return new SkuDetails (String.format (skuJson, "$0.99"));
				} catch (Exception ex) {
				}
			} else if (productID.equals (YEARLY_SUBS_PRODUCTID)) {
				try {
					return new SkuDetails (String.format (skuJson, "$9.99"));
				} catch (Exception ex) {
				}
			}

			return null;
		}

		////////////////////////////////////////////
		// Real purchase flow
		if (_products == null) {
			return null;
		}

		for (SkuDetails sku : _products) {
			if (sku.getSku () == productID) {
				return sku;
			}
		}

		return null;
	}

	private void showOKAlert (String msg, String title) {
		Activity activity = _activityProvider.getActivity ();

		AlertDialog.Builder builder = new AlertDialog.Builder (activity);
		builder.setTitle (title);

		builder.setMessage (msg);

		builder.setPositiveButton (R.string.ok, new DialogInterface.OnClickListener () {
			@Override
			public void onClick (DialogInterface dialog, int which) {
				Activity activity = _activityProvider.getActivity ();
				View view = activity.findViewById (R.id.nav_host_fragment);
				Navigation.findNavController (view).navigateUp ();
			}
		});

		builder.show ();
	}

	private String purchasePath () {
		Activity activity = _activityProvider.getActivity ();
		String purchasePath = FileUtils.pathByAppendingPathComponent (activity.getFilesDir ().getAbsolutePath (), "purchase.dat");
		return purchasePath;
	}

	private void deletePurchase () {
		File file = new File (purchasePath ());
		file.delete ();
	}

	private boolean storePurchaseDate (long purchaseDate, String productID) {
		String str = String.format ("%d:%s", purchaseDate, productID);

		if (!FileUtils.writeFile (purchasePath (), str)) {
			showOKAlert ("Cannot store your purchase on local storage!", "Error");
			return false;
		}

		if (_subscribeChangeListener != null) {
			_subscribeChangeListener.SubscribeChanged ();
		}

		return true;
	}

	private Calendar expirationDate () {
		String strDateAndProductID = FileUtils.readFile (purchasePath ());
		if (strDateAndProductID == null || strDateAndProductID.length () <= 0) {
			return null;
		}

		String[] values = strDateAndProductID.split (":");
		if (values.length < 2) {
			return null;
		}

		long unixValue = Long.parseLong (values[0]);
		Calendar purchaseDate = Calendar.getInstance ();
		purchaseDate.setTimeInMillis (unixValue);

		String productID = values[1];

		if (TEST_PURCHASE) {
			////////////////////////////////////////////
			// Testing purchase

			if (productID.equals (MONTHLY_SUBS_PRODUCTID)) { //Monthly subscription
				purchaseDate.add (Calendar.MINUTE, 5);
			} else if (productID.equals (YEARLY_SUBS_PRODUCTID)) { //Yearly subscription
				purchaseDate.add (Calendar.MINUTE, 60);
			} else {
				return null;
			}
		} else {
			////////////////////////////////////////////
			// Real purchase expiration date (1 month + 3 day lease time)

			if (productID.equals (MONTHLY_SUBS_PRODUCTID)) { //Monthly subscription
				purchaseDate.add (Calendar.MONTH, 1);
			} else if (productID.equals (YEARLY_SUBS_PRODUCTID)) { //Yearly subscription
				purchaseDate.add (Calendar.YEAR, 1);
			} else {
				return null;
			}
			purchaseDate.add (Calendar.DATE, 3); //+ 3 days lease
		}

		return purchaseDate;
	}

	@Override
	public void onPurchasesUpdated (final BillingResult billingResult, @Nullable List<Purchase> purchases) {
		switch (billingResult.getResponseCode ()) {
			case BillingClient.BillingResponseCode.OK: {
				if (purchases != null) {
					for (final Purchase purchase : purchases) {
						handlePurchase (purchase);
					}
				}
				break;
			}
			case BillingClient.BillingResponseCode.USER_CANCELED: {
				if (purchases != null) {
					for (final Purchase purchase : purchases) {
						NetLogger.logEvent ("Subscription_End_UserCancelled", new HashMap<String, String> () {{
							put ("productIdentifier", purchase.getSku ());
							put ("purchaseToken", purchase.getPurchaseToken ());
							put ("orderID", purchase.getOrderId ());
						}});
					}
				}
				break;
			}
			default: {
				if (purchases != null) {
					for (final Purchase purchase : purchases) {
						NetLogger.logEvent ("Subscription_End_Failed", new HashMap<String, String> () {{
							put ("productIdentifier", purchase.getSku ());
							put ("purchaseToken", purchase.getPurchaseToken ());
							put ("orderID", purchase.getOrderId ());
							put ("responseCode", Integer.toString (billingResult.getResponseCode ()));
							put ("responseMsg", billingResult.getDebugMessage ());
						}});
					}
				}
				break;
			}
		}
	}

	private void handlePurchase (final Purchase purchase) {
		if (purchase.getPurchaseState() == Purchase.PurchaseState.PURCHASED) {
			//Grant entitlement to the user
			if (!storePurchaseDate (purchase.getPurchaseTime (), purchase.getSku ())) {
				NetLogger.logEvent ("Subscription_End_CannotStore", new HashMap<String, String> () {{
					put ("productIdentifier", purchase.getSku ());
					put ("purchaseToken", purchase.getPurchaseToken ());
					put ("orderID", purchase.getOrderId ());
				}});
				showOKAlert ("Cannot store your subscription! You will get your refund in some days!", "Error");
				return;
			}

			//Acknowledge the purchase at google
			if (!purchase.isAcknowledged ()) {
				AcknowledgePurchaseParams acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder ()
					.setPurchaseToken (purchase.getPurchaseToken ())
					.build ();
				_billingClient.acknowledgePurchase (acknowledgePurchaseParams, new AcknowledgePurchaseResponseListener () {
					@Override
					public void onAcknowledgePurchaseResponse (BillingResult billingResult) {
						if (billingResult.getResponseCode () == BillingClient.BillingResponseCode.OK) {
							NetLogger.logEvent ("Subscription_End_Acknowledged", new HashMap<String, String> () {{
								put ("productIdentifier", purchase.getSku ());
								put ("purchaseToken", purchase.getPurchaseToken ());
								put ("orderID", purchase.getOrderId ());
							}});
							NetLogger.logPaymentTransaction (purchase.getSku (), purchase.getPurchaseToken (), purchase.getOrderId (), _products);
							showOKAlert ("Subscription purchased successfully!", "Success");
						} else { //Cannot acknowledge
							//Remove user's entitlement
							deletePurchase ();

							//Show some information to the user
							NetLogger.logEvent ("Subscription_End_CannotAcknowledge", new HashMap<String, String> () {{
								put ("productIdentifier", purchase.getSku ());
								put ("purchaseToken", purchase.getPurchaseToken ());
								put ("orderID", purchase.getOrderId ());
							}});
							showOKAlert ("Cannot acknowledge your subscription! You will get your refund in some days!", "Error");
						}
					}
				});
			} else { //Must not acknowledge
				NetLogger.logEvent ("Subscription_End_Purchased", new HashMap<String, String> () {{
					put ("productIdentifier", purchase.getSku ());
					put ("purchaseToken", purchase.getPurchaseToken ());
					put ("orderID", purchase.getOrderId ());
				}});
				NetLogger.logPaymentTransaction (purchase.getSku (), purchase.getPurchaseToken (), purchase.getOrderId (), _products);
				showOKAlert ("Subscription purchased successfully!", "Success");
			}
		} else if (purchase.getPurchaseState() == Purchase.PurchaseState.PENDING) {
			showOKAlert ("You have a pending subscription! " +
				"Finish the subscription process to get your subscription and use the app without limitation...\n" +
				"Order ID: " + purchase.getOrderId (), "Information");

			NetLogger.logEvent ("Subscription_Pending", new HashMap<String, String> () {{
				put ("productIdentifier", purchase.getSku ());
				put ("purchaseToken", purchase.getPurchaseToken ());
				put ("orderID", purchase.getOrderId ());
			}});
		}
	}
	//endregion

	//region Purchase alert
	private String mPendingSubscriptionAlert = null;

	public void setPendingSubscriptionAlert (String msg) {
		mPendingSubscriptionAlert = msg;
	}

	public String popPendingSubscriptionAlert () {
		String msg = mPendingSubscriptionAlert;
		mPendingSubscriptionAlert = null;
		return msg;
	}

	public void showSubscriptionAlert (Context context, final View view, String msg) {
		AlertDialog.Builder builder = new AlertDialog.Builder (context);
		builder.setTitle ("Subscribe Alert!");

		builder.setMessage (msg);

		builder.setNegativeButton (R.string.no, new DialogInterface.OnClickListener () {
			@Override
			public void onClick (DialogInterface dialog, int which) {
				// ... Nothing to do here ...
			}
		});
		builder.setPositiveButton (R.string.yes, new DialogInterface.OnClickListener () {
			@Override
			public void onClick (DialogInterface dialog, int which) {
				Navigation.findNavController (view).navigate (R.id.ShowStore);
			}
		});

		builder.show ();
	}
	//endregion

	//region IsSubscribed implementation
	private static boolean _notSubscribedWithoutDateSent = false;
	private static boolean _notSubscribedWithDateSent = false;
	private static boolean _subscribedSent = false;

	public boolean isSubscribed () {
		final Calendar expiration = expirationDate ();
		if (expiration == null) {
			if (!_notSubscribedWithoutDateSent) {
				NetLogger.logEvent ("Subscription_NotSubscribed", new HashMap<String, String> () {{
					put ("expirationDate", "null");
				}});
				_notSubscribedWithoutDateSent = true;
			}

			return false;
		}

		final Calendar cur = Calendar.getInstance ();
		if (expiration.getTimeInMillis () >= cur.getTimeInMillis ()) {
			if (!_subscribedSent) {
				NetLogger.logEvent ("Subscription_Subscribed", new HashMap<String, String> () {{
					put ("expirationDate", expiration.toString ());
					put ("currentDate", cur.toString ());
				}});
				_subscribedSent = true;
			}

			return true;
		}

		if (!_notSubscribedWithDateSent) {
			NetLogger.logEvent ("Subscription_NotSubscribed", new HashMap<String, String> () {{
				put ("expirationDate", expiration.toString ());
			}});
			_notSubscribedWithDateSent = true;
		}

		return false;
	}
	//endregion
}
