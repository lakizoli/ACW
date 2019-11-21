# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
-keep class !com.zapp.acw.bll.SubscriptionManager*,!com.zapp.acw.bll.Downloader*,com.zapp.acw.bll.** {
   *;
}

-keep class com.zapp.acw.bll.ui.keyboardconfigs.** {
   public *;
}

-keepclassmembers class **.R$* {
	public static <fields>;
}

-keep class **.R$*

# Uncomment this to preserve the line number information for
# debugging stack traces.
-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
-renamesourcefileattribute SourceFile
