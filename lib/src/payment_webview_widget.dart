// src/payment_webview_widget.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A widget that displays a payment webview with custom callbacks
class PaymentWebView extends StatefulWidget {
  /// The URL to load in the webview
  final String url;

  /// Callback when payment is completed
  final Function(String status, String? transactionId, double? amount)? onPaymentComplete;

  /// Callback when there's an error
  final Function(String)? onError;

  /// Custom loading widget
  final Widget? loadingWidget;

  const PaymentWebView({
    Key? key,
    required this.url,
    this.onPaymentComplete,
    this.onError,
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            widget.onError?.call(error.description);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check if the URL contains payment response
            final uri = Uri.parse(request.url);
            
            // You can customize these patterns based on your payment gateway
            if (uri.path.contains('success') || uri.path.contains('payment_success')) {
              widget.onPaymentComplete?.call(
                'success',
                uri.queryParameters['transaction_id'],
                double.tryParse(uri.queryParameters['amount'] ?? ''),
              );
              return NavigationDecision.prevent;
            } else if (uri.path.contains('failed') || uri.path.contains('payment_failed')) {
              widget.onPaymentComplete?.call(
                'failed',
                uri.queryParameters['transaction_id'],
                double.tryParse(uri.queryParameters['amount'] ?? ''),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Center(
            child: widget.loadingWidget ?? const CircularProgressIndicator(),
          ),
      ],
    );
  }
} 