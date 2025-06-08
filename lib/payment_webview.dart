// payment_webview.dart
library payment_webview;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

export 'src/payment_webview_widget.dart';
export 'src/payment_result.dart';
export 'src/payment_config.dart';

/// A Flutter package for handling payment webviews with custom callbacks.
/// 
/// This package provides a simple way to integrate payment webviews into your Flutter app.
/// It handles the webview lifecycle and provides callbacks for payment completion.
/// 
/// Example usage:
/// ```dart
/// PaymentWebView(
///   url: 'https://your-payment-url.com',
///   onPaymentComplete: (result) {
///     print('Payment status: ${result.status}');
///     print('Transaction ID: ${result.transactionId}');
///     print('Amount: ${result.amount}');
///   },
/// )
/// ``` 

/// The result of a payment transaction
class PaymentResult {
  final String status;
  final String? transactionId;
  final double? amount;

  PaymentResult({
    required this.status,
    this.transactionId,
    this.amount,
  });
}

/// A widget that displays a payment webview with custom callbacks
class PaymentWebView extends StatefulWidget {
  /// The URL to load in the webview
  final String url;

  /// Callback when payment is completed
  final Function(PaymentResult) onPaymentComplete;

  /// Callback when there's an error
  final Function(String)? onError;

  /// Callback when the page starts loading
  final Function()? onPageStarted;

  /// Callback when the page finishes loading
  final Function()? onPageFinished;

  const PaymentWebView({
    Key? key,
    required this.url,
    required this.onPaymentComplete,
    this.onError,
    this.onPageStarted,
    this.onPageFinished,
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
            widget.onPageStarted?.call();
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            widget.onPageFinished?.call();
          },
          onWebResourceError: (WebResourceError error) {
            widget.onError?.call(error.description);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle payment completion URLs here
            if (request.url.contains('payment_success')) {
              final uri = Uri.parse(request.url);
              final result = PaymentResult(
                status: 'success',
                transactionId: uri.queryParameters['transaction_id'],
                amount: double.tryParse(uri.queryParameters['amount'] ?? ''),
              );
              widget.onPaymentComplete(result);
              return NavigationDecision.prevent;
            } else if (request.url.contains('payment_failed')) {
              final uri = Uri.parse(request.url);
              final result = PaymentResult(
                status: 'failed',
                transactionId: uri.queryParameters['transaction_id'],
                amount: double.tryParse(uri.queryParameters['amount'] ?? ''),
              );
              widget.onPaymentComplete(result);
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
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
} 