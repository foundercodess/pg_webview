// src/payment_webview_widget.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that displays a webview with support for downloads and external apps
class PaymentWebView extends StatefulWidget {
  /// The URL to load in the webview
  final String url;

  /// Callback when there's an error
  final Function(String)? onError;

  /// Custom loading widget
  final Widget? loadingWidget;

  const PaymentWebView({
    Key? key,
    required this.url,
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
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.parse(request.url);
            
            // Handle UPI URLs
            if (uri.scheme == 'upi' || uri.scheme == 'intent') {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
            }
            
            // Handle file downloads
            if (request.url.contains('download') || 
                request.url.endsWith('.pdf') ||
                request.url.endsWith('.doc') ||
                request.url.endsWith('.docx') ||
                request.url.endsWith('.xls') ||
                request.url.endsWith('.xlsx') ||
                request.url.endsWith('.zip') ||
                request.url.endsWith('.rar')) {
              await _handleDownload(request.url);
              return NavigationDecision.prevent;
            }

            // Handle external links
            if (!uri.host.contains('your-domain.com')) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _handleDownload(String url) async {
    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        widget.onError?.call('Storage permission denied');
        return;
      }

      // Get download directory
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        widget.onError?.call('Could not access download directory');
        return;
      }

      // Get filename from URL
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.last;
      final file = File('${downloadDir.path}/$filename');

      // Download file
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      final bytes = await response.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );
      await file.writeAsBytes(bytes);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded to: ${file.path}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              if (await canLaunchUrl(Uri.file(file.path))) {
                await launchUrl(Uri.file(file.path));
              }
            },
          ),
        ),
      );
    } catch (e) {
      widget.onError?.call('Download failed: $e');
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