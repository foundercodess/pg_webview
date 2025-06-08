// webview.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomWebView extends StatefulWidget {
  final String url;
  final bool javascriptEnabled;
  final Function(String)? onPageStarted;
  final Function(String)? onPageFinished;
  final Function(String)? onError;
  final Function(Map<String, dynamic>)? onPaymentComplete;

  const CustomWebView({
    Key? key,
    required this.url,
    this.javascriptEnabled = true,
    this.onPageStarted,
    this.onPageFinished,
    this.onError,
    this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  static const platform = MethodChannel('com.example.customized_webview/webview');
  late int _webViewId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didUpdateWidget(CustomWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && _isInitialized) {
      _loadUrl(widget.url);
    }
  }

  Future<void> _initWebView() async {
    try {
      _webViewId = await platform.invokeMethod('createWebView', {
        'url': widget.url,
        'javascriptEnabled': widget.javascriptEnabled,
      });

      platform.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onPageStarted':
            widget.onPageStarted?.call(call.arguments as String);
            break;
          case 'onPageFinished':
            widget.onPageFinished?.call(call.arguments as String);
            break;
          case 'onError':
            widget.onError?.call(call.arguments as String);
            break;
          case 'onPaymentComplete':
            if (call.arguments != null) {
              final result = Map<String, dynamic>.from(
                Map<String, dynamic>.from(call.arguments as Map)
              );
              widget.onPaymentComplete?.call(result);
            }
            break;
        }
      });

      _isInitialized = true;
    } on PlatformException catch (e) {
      print('Error initializing WebView: ${e.message}');
      widget.onError?.call('Failed to initialize WebView: ${e.message}');
    }
  }

  Future<void> _loadUrl(String url) async {
    if (!_isInitialized) return;
    
    try {
      await platform.invokeMethod('loadUrl', {
        'id': _webViewId,
        'url': url,
      });
    } on PlatformException catch (e) {
      print('Error loading URL: ${e.message}');
      widget.onError?.call('Failed to load URL: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'webview_$_webViewId',
      creationParams: <String, dynamic>{
        'url': widget.url,
        'javascriptEnabled': widget.javascriptEnabled,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      platform.invokeMethod('disposeWebView', {'id': _webViewId});
    }
    super.dispose();
  }
} 