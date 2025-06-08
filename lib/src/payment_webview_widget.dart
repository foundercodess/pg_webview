// src/payment_webview_widget.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_config.dart';
import 'payment_result.dart';

/// A widget that displays a payment webview with custom callbacks
class PaymentWebView extends StatefulWidget {
  /// The payment configuration
  final PaymentConfig config;

  /// Callback when payment is completed
  final Function(PaymentResult) onPaymentComplete;

  /// Callback when there's an error
  final Function(String)? onError;

  /// Callback when the page starts loading
  final Function()? onPageStarted;

  /// Callback when the page finishes loading
  final Function()? onPageFinished;

  /// Custom loading widget
  final Widget? loadingWidget;

  const PaymentWebView({
    Key? key,
    required this.config,
    required this.onPaymentComplete,
    this.onError,
    this.onPageStarted,
    this.onPageFinished,
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
            final url = request.url;
            if (url.contains(widget.config.successUrlPattern)) {
              final uri = Uri.parse(url);
              final result = PaymentResult(
                status: 'success',
                transactionId: uri.queryParameters['transaction_id'],
                amount: double.tryParse(uri.queryParameters['amount'] ?? ''),
              );
              widget.onPaymentComplete(result);
              return NavigationDecision.prevent;
            } else if (url.contains(widget.config.failureUrlPattern)) {
              final uri = Uri.parse(url);
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
      );

    // Set headers if provided
    if (widget.config.headers != null) {
      final headers = widget.config.headers!;
      _controller.loadRequest(
        Uri.parse(widget.config.buildPaymentUrl()),
        headers: headers,
      );
    } else {
      _controller.loadRequest(Uri.parse(widget.config.buildPaymentUrl()));
    }
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