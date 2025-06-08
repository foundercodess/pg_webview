package com.example.customized_webview

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.JavascriptInterface
import android.webkit.ValueCallback
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.customized_webview/webview"
    private var webViewCounter = 0
    private val webViews = mutableMapOf<Int, WebView>()
    private var paymentCallback: MethodChannel.Result? = null
    private var isPaymentInProgress = false

    override fun onDestroy() {
        // Clean up all WebViews
        webViews.values.forEach { webView ->
            try {
                webView.stopLoading()
                webView.clearHistory()
                webView.clearCache(true)
                webView.loadUrl("about:blank")
                webView.onPause()
                webView.removeAllViews()
                webView.destroy()
            } catch (e: Exception) {
                Log.e("WebView", "Error cleaning up WebView", e)
            }
        }
        webViews.clear() 
        super.onDestroy()
    }

    override fun onPause() {
        webViews.values.forEach { webView ->
            try {
                webView.onPause()
            } catch (e: Exception) {
                Log.e("WebView", "Error pausing WebView", e)
            }
        }
        super.onPause()
    }

    override fun onResume() {
        webViews.values.forEach { webView ->
            try {
                webView.onResume()
            } catch (e: Exception) {
                Log.e("WebView", "Error resuming WebView", e)
            }
        }
        super.onResume()
    }

    inner class WebAppInterface(private val context: Context) {
        @JavascriptInterface
        fun share(title: String, text: String, url: String) {
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_SUBJECT, title)
                putExtra(Intent.EXTRA_TEXT, "$text\n$url")
            }
            val chooserIntent = Intent.createChooser(shareIntent, "Share via")
            chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooserIntent)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createWebView" -> {
                    val url = call.argument<String>("url")
                    val javascriptEnabled = call.argument<Boolean>("javascriptEnabled") ?: true
                    
                    if (url != null) {
                        try {
                            val webViewId = webViewCounter++
                            val webView = createWebView(url, javascriptEnabled)
                            webViews[webViewId] = webView
                            
                            flutterEngine.platformViewsController.registry.registerViewFactory(
                                "webview_$webViewId",
                                WebViewFactory(webView)
                            )
                            
                            result.success(webViewId)
                        } catch (e: Exception) {
                            Log.e("WebView", "Error creating WebView", e)
                            result.error("WEBVIEW_ERROR", "Failed to create WebView: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL cannot be null", null)
                    }
                }
                "disposeWebView" -> {
                    val id = call.argument<Int>("id")
                    if (id != null) {
                        val webView = webViews.remove(id)
                        if (webView != null) {
                            try {
                                webView.stopLoading()
                                webView.clearHistory()
                                webView.clearCache(true)
                                webView.loadUrl("about:blank")
                                webView.onPause()
                                webView.removeAllViews()
                                webView.destroy()
                            } catch (e: Exception) {
                                Log.e("WebView", "Error disposing WebView", e)
                            }
                        }
                        result.success(null)
                    } else {
                        result.error("INVALID_ID", "WebView ID cannot be null", null)
                    }
                }
                "loadUrl" -> {
                    val id = call.argument<Int>("id")
                    val url = call.argument<String>("url")
                    
                    if (id != null && url != null) {
                        val webView = webViews[id]
                        if (webView != null) {
                            try {
                                webView.loadUrl(url)
                                result.success(null)
                            } catch (e: Exception) {
                                Log.e("WebView", "Error loading URL: $url", e)
                                result.error("LOAD_URL_ERROR", "Failed to load URL: ${e.message}", null)
                            }
                        } else {
                            result.error("INVALID_WEBVIEW", "WebView not found for ID: $id", null)
                        }
                    } else {
                        result.error("INVALID_PARAMS", "ID and URL cannot be null", null)
                    }
                }
                "setPaymentCallback" -> {
                    paymentCallback = result
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val data = intent.data
        if (data != null && data.scheme == "customizedwebview") {
            // Handle payment return
            val status = data.getQueryParameter("status")
            val transactionId = data.getQueryParameter("transactionId")
            val amount = data.getQueryParameter("amount")
            
            val result = mapOf(
                "status" to status,
                "transactionId" to transactionId,
                "amount" to amount
            )
            
            paymentCallback?.success(result)
            paymentCallback = null
        }
    }

    private fun launchPaytmApp(url: String): Boolean {
        try {
            isPaymentInProgress = true
            // Try to launch Paytm app directly
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            // Check if Paytm app is installed
            val paytmPackage = "net.one97.paytm"
            val packageManager = context.packageManager
            val paytmInstalled = try {
                packageManager.getPackageInfo(paytmPackage, 0)
                true
            } catch (e: Exception) {
                false
            }

            if (paytmInstalled) {
                // Set Paytm as the target package
                intent.setPackage(paytmPackage)
                context.startActivity(intent)
                return true
            } else {
                // If Paytm is not installed, try to open in browser
                val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                browserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(browserIntent)
                return true
            }
        } catch (e: Exception) {
            Log.e("WebView", "Error launching Paytm: $url", e)
            isPaymentInProgress = false
            return false
        }
    }

    @SuppressLint("SetJavaScriptEnabled", "JavascriptInterface")
    private fun createWebView(url: String, javascriptEnabled: Boolean): WebView {
        return WebView(context).apply {
            settings.apply {
                javaScriptEnabled = javascriptEnabled
                domStorageEnabled = true
                setSupportZoom(true)
                builtInZoomControls = true
                displayZoomControls = false
                loadWithOverviewMode = true
                useWideViewPort = true
                setSupportMultipleWindows(true)
                allowFileAccess = true
                allowContentAccess = true
                databaseEnabled = true
                setGeolocationEnabled(true)
                mediaPlaybackRequiresUserGesture = false
            }
            
            // Add JavaScript interface for sharing
            addJavascriptInterface(WebAppInterface(context), "Android")
            
            webViewClient = object : WebViewClient() {
                override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    Log.d("WebView", "Page started loading: $url")
                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                        .invokeMethod("onPageStarted", url)
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    Log.d("WebView", "Page finished loading: $url")
                    
                    // Check if this is a success page or if we're tracking a payment
                    if (isPaymentInProgress || url?.contains("success") == true || 
                        url?.contains("payment-success") == true || 
                        url?.contains("payment/status") == true) {
                        
                        // Extract payment details from the page
                        view?.evaluateJavascript("""
                            (function() {
                                try {
                                    // Try to find payment status in various common formats
                                    let status = 'success';
                                    let transactionId = '';
                                    let amount = '';
                                    
                                    // Check for common success indicators
                                    if (document.body.innerText.toLowerCase().includes('payment successful') ||
                                        document.body.innerText.toLowerCase().includes('transaction successful') ||
                                        document.body.innerText.toLowerCase().includes('payment completed')) {
                                        status = 'success';
                                    } else if (document.body.innerText.toLowerCase().includes('payment failed') ||
                                             document.body.innerText.toLowerCase().includes('transaction failed')) {
                                        status = 'failed';
                                    }
                                    
                                    // Try to find transaction ID in various formats
                                    const transactionIdPatterns = [
                                        /transaction[_-]?id[\\s:]+([a-zA-Z0-9]+)/i,
                                        /txn[_-]?id[\\s:]+([a-zA-Z0-9]+)/i,
                                        /order[_-]?id[\\s:]+([a-zA-Z0-9]+)/i
                                    ];
                                    
                                    for (const pattern of transactionIdPatterns) {
                                        const match = document.body.innerText.match(pattern);
                                        if (match && match[1]) {
                                            transactionId = match[1];
                                            break;
                                        }
                                    }
                                    
                                    // Try to find amount in various formats
                                    const amountPatterns = [
                                        /amount[\\s:]+([\\d.]+)/i,
                                        /total[\\s:]+([\\d.]+)/i,
                                        /payment[\\s:]+([\\d.]+)/i
                                    ];
                                    
                                    for (const pattern of amountPatterns) {
                                        const match = document.body.innerText.match(pattern);
                                        if (match && match[1]) {
                                            amount = match[1];
                                            break;
                                        }
                                    }
                                    
                                    // If we found a transaction ID, consider it a success
                                    if (transactionId) {
                                        status = 'success';
                                    }
                                    
                                    return JSON.stringify({
                                        status: status,
                                        transactionId: transactionId,
                                        amount: amount
                                    });
                                } catch(e) {
                                    return JSON.stringify({
                                        status: 'error',
                                        error: e.message
                                    });
                                }
                            })()
                        """.trimIndent()) { result ->
                            // Send result back to Flutter
                            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                                .invokeMethod("onPaymentComplete", result)
                            
                            // Reset payment tracking
                            isPaymentInProgress = false
                        }
                    }
                    
                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                        .invokeMethod("onPageFinished", url)
                }

                override fun onReceivedError(
                    view: WebView?,
                    request: WebResourceRequest?,
                    error: WebResourceError?
                ) {
                    super.onReceivedError(view, request, error)
                    val errorMessage = "Error loading ${request?.url}: ${error?.description}"
                    Log.e("WebView", errorMessage)
                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                        .invokeMethod("onError", errorMessage)
                }

                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val url = request?.url.toString()
                    Log.d("WebView", "Intercepting URL: $url")

                    return when {
                        // Handle Paytm URLs
                        url.startsWith("paytmmp://") -> {
                            launchPaytmApp(url)
                        }
                        // Handle other payment intents
                        url.startsWith("upi://") || 
                        url.startsWith("intent://") || 
                        url.startsWith("market://") || 
                        url.startsWith("tel:") || 
                        url.startsWith("whatsapp://") -> {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                if (intent.resolveActivity(context.packageManager) != null) {
                                    context.startActivity(intent)
                                } else {
                                    // If the app is not installed, try to open in browser
                                    val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                    browserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    context.startActivity(browserIntent)
                                }
                                true
                            } catch (e: Exception) {
                                Log.e("WebView", "Error launching intent: $url", e)
                                true
                            }
                        }
                        // Handle regular URLs
                        else -> {
                            view?.loadUrl(url)
                            true
                        }
                    }
                }
            }
            
            webChromeClient = object : WebChromeClient() {
                override fun onShowFileChooser(
                    webView: WebView?,
                    filePathCallback: ValueCallback<Array<Uri>>?,
                    fileChooserParams: FileChooserParams?
                ): Boolean {
                    // Handle file chooser if needed
                    return super.onShowFileChooser(webView, filePathCallback, fileChooserParams)
                }
            }
            
            try {
                Log.d("WebView", "Loading URL: $url")
                loadUrl(url)
            } catch (e: Exception) {
                Log.e("WebView", "Error loading URL: $url", e)
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onError", "Failed to load URL: ${e.message}")
            }
        }
    }
}

class WebViewFactory(private val webView: WebView) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return object : PlatformView {
            override fun getView(): WebView = webView
            override fun dispose() {
                try {
                    webView.stopLoading()
                    webView.clearHistory()
                    webView.clearCache(true)
                    webView.loadUrl("about:blank")
                    webView.onPause()
                    webView.removeAllViews()
                    webView.destroy()
                } catch (e: Exception) {
                    Log.e("WebView", "Error disposing WebView", e)
                }
            }
        }
    }
}
