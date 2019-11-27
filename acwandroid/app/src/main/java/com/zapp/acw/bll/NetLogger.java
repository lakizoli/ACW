package com.zapp.acw.bll;

import android.app.Activity;
import android.content.Context;
import android.provider.Settings;
import android.util.Log;

import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.SkuDetails;
import com.flurry.android.FlurryAgent;
import com.flurry.android.FlurryPerformance;
import com.zapp.acw.BuildConfig;
import com.zapp.acw.FileUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.text.NumberFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;
import java.util.UUID;

public final class NetLogger {
	private static final boolean SIMULATE_NETLOGGER = BuildConfig.SIMULATE_NETLOGGER;
	private static String mEventsPath;

	public static void startSession (Context context, String eventsPath) {
		setEventsPath (eventsPath);
		mEventsPath = eventsPath;

		if (SIMULATE_NETLOGGER) {
			Log.i ("NetLogger", "Netlogger started");
		} else {
			FlurryAgent.setVersionName (BuildConfig.VERSION_NAME);

			FlurryAgent.setUserId (getFlurryUserID (context));

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

	private static String flurryUserIDPath (Context context) {
		String userIDPath = FileUtils.pathByAppendingPathComponent (context.getFilesDir ().getAbsolutePath (), "flurry.dat");
		return userIDPath;
	}

	private static String getFlurryUserID (Context context) {
		String userIDPath = flurryUserIDPath (context);
		String userID = FileUtils.readFile (userIDPath);
		if (userID == null) {
			userID = UUID.randomUUID ().toString ();
			FileUtils.writeFile (userIDPath, userID);
		}

		return userID;
	}

	//region Crash logging
	private static native void setEventsPath (String eventsPath);

	static final class LogExceptionHandler implements Thread.UncaughtExceptionHandler {
		private Thread.UncaughtExceptionHandler defaultUEH;

		public LogExceptionHandler (Context context) {
			defaultUEH = Thread.getDefaultUncaughtExceptionHandler ();
		}

		public static Map<String, String> composeEventParams (Thread thread, Throwable ex) {
			StringBuilder builder = new StringBuilder ();

			boolean first = true;
			ArrayList<Throwable> throwables = new ArrayList<> ();
			throwables.add (ex);

			while (throwables.size () > 0) {
				Throwable exception = throwables.remove (0);
				StackTraceElement[] elements = exception.getStackTrace ();
				if (elements != null && elements.length > 0) {
					if (!first) {
						builder.append ("CausedBy:");
					}
					first = false;

					for (StackTraceElement element : elements) {
						builder.append (element);
						builder.append ("|");
					}
				}
				Throwable child = exception.getCause ();
				if (child != null) {
					throwables.add (child);
				}
			}

			String stackTrace = null;
			if (builder.length () > 0) {
				stackTrace = builder.toString ();
			}

			return composeEventParams (thread.getId (), thread.getName (), ex.getClass ().getSimpleName (), ex.getMessage (), stackTrace);
		}

		public static Map<String, String> composeEventParams (long threadId, String threadName, String className, String message, String stackTrace) {
			// Send flurry event
			Map<String, String> param = new LinkedHashMap<String, String> ();

			StringBuilder major = new StringBuilder ();
			major.append ("{ Class : ");
			major.append (className);
			major.append ("; Msg : ");
			major.append (message);
			major.append ("; ThreadId : ");
			major.append (Long.valueOf (threadId).toString ());
			major.append ("; ThreadName : ");
			major.append (threadName);
			major.append ("; TS : ");
			major.append (NetLogger.timeStamp ());
			major.append (" }");
			param.put ("MajorInfo", major.toString ());

			if (stackTrace != null && stackTrace.length () > 0) {
				int chunkLen = 250;
				int chunkCount = stackTrace.length () / chunkLen;
				if (stackTrace.length () % chunkLen > 0) {
					++chunkCount;
				}

				for (int i = 0; i < chunkCount && i < 8; ++i) {
					String stackItem = null;
					if (i == chunkCount - 1) { // Last chunk
						stackItem = stackTrace.substring (i * chunkLen);
					} else { // Full chunk
						stackItem = stackTrace.substring (i * chunkLen, (i + 1) * chunkLen);
					}
					param.put ("CallStack_" + i, stackItem);
				}
			}

			return param;
		}

		@Override
		public void uncaughtException (Thread thread, Throwable ex) {
			// Send flurry event
			Map<String, String> params = composeEventParams (thread, ex);
			if (SIMULATE_NETLOGGER) {
				Log.e ("NetLogger", "UncaughtException " + params);
			} else {
				FlurryAgent.logEvent ("UncaughtException", params, true);
			}

			// Handle default
			if (defaultUEH != null) {
				defaultUEH.uncaughtException (thread, ex);
			}
		}
	}

	private static String timeStamp () {
		SimpleDateFormat SDF = new SimpleDateFormat ("yyyy-MM-dd HH:mm:ss.SSS");
		Calendar c = Calendar.getInstance ();
		SDF.setTimeZone (TimeZone.getTimeZone ("UTC"));
		return SDF.format (c.getTime ());
	}

	public static void throwFromSignal (String signalName, String signalParams) {
		//Compose event params
		Map<String, String> params = LogExceptionHandler.composeEventParams (Thread.currentThread (), new RuntimeException (signalParams));

		//Write event to file
		writeEventFile (signalName, params);
	}

	private static void writeEventFile (String signalName, Map<String, String> params) {
		try {
			//Compose file path
			String fileName = UUID.randomUUID () + ".event";

			File dir = new File (mEventsPath);
			if (!dir.exists ()) {
				dir.mkdirs ();
			}

			//Write event to file
			FileOutputStream fileOut = new FileOutputStream (mEventsPath + "/" + fileName);
			ObjectOutputStream out = new ObjectOutputStream (fileOut);
			out.writeObject (signalName);
			out.writeObject (params);
			out.close ();
			fileOut.close ();
		} catch (IOException ex) {
			ex.printStackTrace ();
		}
	}

	public static void sendAllEventFromFiles () {
		//Wait the active flurry session
		if (!SIMULATE_NETLOGGER) {
			try {
				while (!FlurryAgent.isSessionActive ()) {
					Thread.sleep (100);
				}
			} catch (InterruptedException ex) {
				ex.printStackTrace ();
			}
		}

		//Compose path and collect event files
		File eventDirectory = new File (mEventsPath);
		if (!eventDirectory.exists ()) {
			return;
		}

		//Convert all native crash file to event file
		convertCrashFilesToEventFiles (eventDirectory);

		//Collect event files
		File[] events = eventDirectory.listFiles ();
		for (File event : events) {
			if (!event.isFile ()) { //check file
				continue;
			}

			String name = event.getName ();
			int posExt = name.lastIndexOf (".event");
			if (posExt <= 0) { //check extension
				continue;
			}

			try {
				String filePath = event.getAbsolutePath ();

				//Read event from file
				FileInputStream fileIn = new FileInputStream (filePath);
				ObjectInputStream in = new ObjectInputStream (fileIn);
				String eventName = (String) in.readObject ();
				Map<String, String> params = (Map<String, String>) in.readObject ();
				in.close ();
				fileIn.close ();

				//Send event to flurry
				if (SIMULATE_NETLOGGER) {
					Log.e ("NetLogger", "event " + eventName + " " + params.toString ());
				} else {
					FlurryAgent.logEvent (eventName, params, true);
				}

				//Delete the event file
				File file = new File (filePath);
				file.delete ();
			} catch (ClassNotFoundException cnfEx) {
				cnfEx.printStackTrace ();
			} catch (IOException ex) {
				ex.printStackTrace ();
			}
		}
	}

	private static void convertCrashFilesToEventFiles (File eventDirectory) {
		File[] files = eventDirectory.listFiles ();
		for (File file : files) {
			if (!file.isFile ()) { //check file
				continue;
			}

			String name = file.getName ();
			int posExt = name.lastIndexOf (".nativecrash");
			if (posExt <= 0) { //check extension
				continue;
			}

			//Read crash file's content
			String signalName = null;
			String nativeParams = null;
			String stackTrace = null;
			try {
				FileInputStream is = new FileInputStream (file.getAbsolutePath ());

				ByteBuffer buffer = ByteBuffer.allocate (4);
				buffer.order (ByteOrder.LITTLE_ENDIAN);

				is.read (buffer.array ());
				byte[] sigNameBuffer = new byte[buffer.getInt ()];
				is.read (sigNameBuffer);
				signalName = new String (sigNameBuffer, "UTF-8");

				buffer = ByteBuffer.allocate (4);
				buffer.order (ByteOrder.LITTLE_ENDIAN);

				is.read (buffer.array ());
				byte[] parsBuffer = new byte[buffer.getInt ()];
				is.read (parsBuffer);
				nativeParams = new String (parsBuffer, "UTF-8");

				buffer = ByteBuffer.allocate (4);
				buffer.order (ByteOrder.LITTLE_ENDIAN);

				is.read (buffer.array ());
				byte[] stackTraceBuffer = new byte[buffer.getInt ()];
				is.read (stackTraceBuffer);
				stackTrace = new String (stackTraceBuffer, "UTF-8");

				is.close ();
				file.delete ();
			} catch (IOException ex) {
				ex.printStackTrace ();
			}

			if (signalName == null || nativeParams == null || stackTrace == null) {
				continue;
			}

			//Compose event params
			Map<String, String> params = LogExceptionHandler.composeEventParams (0, "native", "native", nativeParams, stackTrace);

			//Write event to file
			writeEventFile (signalName, params);
		}
	}
	//endregion
}
