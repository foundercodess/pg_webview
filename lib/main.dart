// main.dart
import 'package:flutter/material.dart';
import 'webview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom WebView Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://www.google.com',
  );
  String _currentUrl = 'https:\/\/ekqr.info\/payment7\/instant-pay\/ad780c5986cfb12bf867dc2f9051754124f869cc784cf6879112efc4ebca784f';
  String _status = '';
  Map<String, dynamic>? _paymentResult;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _loadUrl() {
    setState(() {
      _currentUrl = _urlController.text;
      _status = 'Loading...';
      _paymentResult = null;
    });
  }

  void _handlePaymentComplete(Map<String, dynamic> result) {
    setState(() {
      _paymentResult = result;
      _status = 'Payment completed: ${result['status']}';
    });

    // Show payment result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['status'] == 'success' ? 'Payment Successful' : 'Payment Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result['transactionId'] != null)
              Text('Transaction ID: ${result['transactionId']}'),
            if (result['amount'] != null)
              Text('Amount: ${result['amount']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom WebView Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Enter URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadUrl,
                  child: const Text('Go'),
                ),
              ],
            ),
          ),
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_status),
            ),
          if (_paymentResult != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Status: ${_paymentResult!['status']}'),
                      if (_paymentResult!['transactionId'] != null)
                        Text('Transaction ID: ${_paymentResult!['transactionId']}'),
                      if (_paymentResult!['amount'] != null)
                        Text('Amount: ${_paymentResult!['amount']}'),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: CustomWebView(
              url: _currentUrl,
              onPageStarted: (url) {
                setState(() {
                  _status = 'Loading: $url';
                });
              },
              onPageFinished: (url) {
                setState(() {
                  _status = 'Loaded: $url';
                });
              },
              onError: (error) {
                setState(() {
                  _status = 'Error: $error';
                });
              },
              onPaymentComplete: _handlePaymentComplete,
            ),
          ),
        ],
      ),
    );
  }
}
