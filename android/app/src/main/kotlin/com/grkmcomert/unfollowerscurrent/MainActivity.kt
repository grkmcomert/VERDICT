package com.grkmcomert.unfollowerscurrent

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.webkit.CookieManager
import android.webkit.WebStorage
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.grkmcomert.unfollowerscurrent/cookie"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getCookies") {
                val url = call.argument<String>("url")


                val cookieManager = CookieManager.getInstance()
                val cookies = cookieManager.getCookie(url)

                if (cookies != null) {

                    result.success(cookies)
                } else {

                    result.error("NO_COOKIE", "Cookie bulunamadı", null)
                }
            } else if (call.method == "clearCookies") {
                val cookieManager = CookieManager.getInstance()
                try {
                    cookieManager.removeSessionCookies(null)
                    cookieManager.removeAllCookies { removed ->
                        cookieManager.flush()
                        WebStorage.getInstance().deleteAllData()
                        result.success(removed)
                    }
                } catch (e: Exception) {
                    result.error("CLEAR_COOKIE_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Register the native ad factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "adFactoryExample",
            NativeAdFactoryExample(layoutInflater)
        )
    }

    override fun cleanUpFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "adFactoryExample")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
