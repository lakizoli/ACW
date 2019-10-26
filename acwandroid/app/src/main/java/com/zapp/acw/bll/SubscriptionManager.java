package com.zapp.acw.bll;

import android.app.Activity;
import android.content.Context;
import android.content.DialogInterface;
import android.util.Log;
import android.view.View;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.SkuDetails;
import com.android.billingclient.api.SkuDetailsParams;
import com.android.billingclient.api.SkuDetailsResponseListener;
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
	// Testing in app purchase
	private boolean TEST_PURCHASE = false;

	// Answer types of in app purchase test
	private boolean TEST_PURCHASE_SUCCEEDED = false;
	private boolean TEST_PURCHASE_FAILED = false;

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

	public void connectBilling (final Activity activity) {
		//Check multiple call of connect
		if (_isConnectBillingRunning || _isBillingConnected) {
			return;
		}
		_isConnectBillingRunning = true;
		_isBillingConnected = false;

		//Connect billing
		if (_billingClient == null) {
			SubscriptionManager man = SubscriptionManager.sharedInstance ();
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

					// The BillingClient is ready. You can query purchases here.
					//TODO: ...
				} else { //Something wrong with billing
					reconnectAfterDelay (activity, 20000);
				}
			}

			@Override
			public void onBillingServiceDisconnected () {
				// Try to restart the connection on the next request to
				// Google Play by calling the startConnection() method.

				reconnectAfterDelay (activity, 20000);
			}
		});
	}

	private void reconnectAfterDelay (final Activity activity, int delay) {
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
				connectBilling (activity);
			}
		}, delay);
	}

	public SkuDetails getSubscribedProductForMonth () {
		return getSubscribedProductWithID (MONTHLY_SUBS_PRODUCTID);
	}

	public SkuDetails getSubscribedProductForYear () {
		return getSubscribedProductWithID (YEARLY_SUBS_PRODUCTID);
	}

	public void buyProduct (Activity activity, View view, final SkuDetails product) {
		if (!_isBillingConnected) {
			return;
		}

		if (product == null) {
			NetLogger.logEvent ("Subscription_Buy_ProductNotFound");

			showOKAlert (activity, view, "Product not available!", "Subscription error!");
			return;
		}

		BillingResult featureRes = _billingClient.isFeatureSupported (BillingClient.FeatureType.SUBSCRIPTIONS);
		if (featureRes.getResponseCode () != BillingClient.BillingResponseCode.OK) {
			NetLogger.logEvent ("Subscription_Buy_NotSupported", new HashMap<String, Object> () {{
				put ("productIdentifier", product.getSku ());
			}});

			showOKAlert (activity, view, "Subscriptions are not available on this device!", "Subscription error!");
			return;
		}

		NetLogger.logEvent ("Subscription_Buy", new HashMap<String, Object> () {{
			put ("productIdentifier", product.getSku ());
		}});

		BillingFlowParams flowParams = BillingFlowParams.newBuilder ()
			.setSkuDetails (product)
			.build ();
		final BillingResult billingFlowResult = _billingClient.launchBillingFlow (activity, flowParams);
		if (billingFlowResult.getResponseCode () != BillingClient.BillingResponseCode.OK) {
			NetLogger.logEvent ("Subscription_Buy_Failure", new HashMap<String, Object> () {{
				put ("productIdentifier", product.getSku ());
				put ("error", billingFlowResult.getDebugMessage ());
			}});

			showOKAlert (activity, view, "Cannot start billing flow!", "Subscription error!");
		}
	}

	private SkuDetails getSubscribedProductWithID (String productID) {
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

	private void showOKAlert (Context context, final View view, String msg, String title) {
		AlertDialog.Builder builder = new AlertDialog.Builder (context);
		builder.setTitle (title);

		builder.setMessage (msg);

		builder.setPositiveButton (R.string.ok, new DialogInterface.OnClickListener () {
			@Override
			public void onClick (DialogInterface dialog, int which) {
				Navigation.findNavController (view).navigateUp ();
			}
		});

		builder.show ();
	}

	private String purchasePath (Context context) {
		String purchasePath = FileUtils.pathByAppendingPathComponent (context.getFilesDir ().getAbsolutePath (),  "purchase.dat");
		return purchasePath;
	}

	private void deletePurchase (Context context) {
		File file = new File (purchasePath (context));
		file.delete ();
	}

	private boolean storePurchaseDate (Context context, View view, long purchaseDate, String productID) {
		String str = String.format ("%d:%s", purchaseDate, productID);

		if (!FileUtils.writeFile (purchasePath (context), str)) {
			showOKAlert (context, view, "Cannot store your purchase on local storage!", "Error");
			return false;
		}

		return true;
	}

	private Calendar expirationDate (Context context) {
		String strDateAndProductID = FileUtils.readFile (purchasePath (context));
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
//		NSArray<NSString*> *usedProductIDs = [self productIDs];
//
//		NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
//	#ifdef TEST_SANDBOX_PURCHASE
//		if ([productID compare:[usedProductIDs objectAtIndex:MONTH_INDEX]] == NSOrderedSame) { //Monthly subscription
//			[dateComponents setMinute:5];
//		} else if ([productID compare:[usedProductIDs objectAtIndex:YEAR_INDEX]] == NSOrderedSame) { //Yearly subscription
//			[dateComponents setMinute:60];
//		} else {
//			return nil;
//		}
//	#else //TEST_SANDBOX_PURCHASE
//		//////////////////////////////
//		// Real purchase expiration date (1 month + 3 day lease time)
//		//////////////////////////////
//
//		if ([productID compare:[usedProductIDs objectAtIndex:MONTH_INDEX]] == NSOrderedSame) { //Monthly subscription
//			[dateComponents setMonth:1];
//		} else if ([productID compare:[usedProductIDs objectAtIndex:YEAR_INDEX]] == NSOrderedSame) { //Yearly subscription
//			[dateComponents setYear:1];
//		} else {
//			return nil;
//		}
//		[dateComponents setDay:3]; //+ 3 days lease
//	#endif //TEST_SANDBOX_PURCHASE
//
//		NSCalendar *calendar = [NSCalendar currentCalendar];
//		NSDate *expirationDatePlusLease = [calendar dateByAddingComponents:dateComponents toDate:purchaseDate options:0];
//		return expirationDatePlusLease;
		return null;
	}

	@Override
	public void onPurchasesUpdated (BillingResult billingResult, @Nullable List<Purchase> purchases) {
		switch (billingResult.getResponseCode ()) {
			case BillingClient.BillingResponseCode.OK: {
				if (purchases != null) {
					//TODO: ...
				}
				break;
			}
			case BillingClient.BillingResponseCode.USER_CANCELED: {
				break;
			}
			case BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED: {
				break;
			}
			case BillingClient.BillingResponseCode.ITEM_NOT_OWNED: {
				break;
			}
			default: {
				break;
			}
		}

		//TODO: implement
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

	public boolean isSubscribed () {
		return false;
	}
}
