package com.zapp.acw.bll;

import android.content.Context;
import android.util.Log;

import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.SkuDetails;
import com.flurry.android.FlurryAgent;
import com.flurry.android.FlurryPerformance;
import com.zapp.acw.BuildConfig;

import java.text.NumberFormat;
import java.text.ParseException;
import java.util.HashMap;
import java.util.List;

public final class NetLogger {
	private static final boolean SIMULATE_NETLOGGER = BuildConfig.SIMULATE_NETLOGGER;

	public static void startSession (Context context) {
		if (SIMULATE_NETLOGGER) {
			Log.i ("NetLogger", "Netlogger started");
		} else {
			FlurryAgent.setVersionName (BuildConfig.VERSION_NAME);

			new FlurryAgent.Builder ()
				.withCaptureUncaughtExceptions (true)
				.withIncludeBackgroundSessionsInMetrics (true)
				.withLogLevel (Log.VERBOSE)
				.withPerformanceMetrics (FlurryPerformance.All)
				.build (context, "MRK2C3XSMV7BJY7PKZTX");
		}
	}

	public static void logEvent (String eventName) {
		if (SIMULATE_NETLOGGER) {
			Log.i ("NetLogger", "NetLogger event: " + eventName);
		} else {
			FlurryAgent.logEvent (eventName);
		}
	}

	public static void logEvent (String eventName, HashMap<String, String> params) {
		if (SIMULATE_NETLOGGER) {
			Log.i ("NetLogger", "NetLogger event: " + eventName + " withParameters: " + params.toString ());
		} else {
			FlurryAgent.logEvent (eventName, params);
		}
	}

	public static void logPaymentTransaction (String sku, final String purchaseToken, String orderID, List<SkuDetails> products) {
		if (SIMULATE_NETLOGGER) {
			Log.i ("NetLogger", "NetLogger payment! sku:" + sku + ", purchaseToken: " + purchaseToken + ", orederID: " + orderID);
		} else {
			double price = 0;
			String currency = "";
			for (SkuDetails product : products) {
				if (product.getSku () == sku) {
					currency = product.getPriceCurrencyCode ();

					try {
						NumberFormat nf = NumberFormat.getCurrencyInstance ();
						Number priceValue = nf.parse (product.getPrice ());
						price = priceValue.doubleValue ();
					} catch (ParseException ex) {
						price = 0;
					}
					break;
				}
			}

			FlurryAgent.logPayment (sku, sku, 1, price, currency, orderID, new HashMap<String, String> () {{
				put ("purchaseToken", purchaseToken);
			}});
		}
	}
}
