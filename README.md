# Payment WebView

A Flutter package for handling payment webviews with custom callbacks. This package provides a simple way to integrate payment webviews into your Flutter app with support for custom headers, query parameters, and payment result handling.

## Features

- Simple API for integrating payment webviews
- Support for custom headers and query parameters
- Configurable success and failure URL patterns
- Customizable loading indicator
- Type-safe payment results
- JSON serialization support
- Error handling
- Page load status callbacks

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  payment_webview: ^0.1.0
```

## Usage

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:payment_webview/payment_webview.dart';

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: PaymentWebView(
        config: PaymentConfig(
          baseUrl: 'https://your-payment-gateway.com/pay',
          queryParams: {
            'amount': '100.00',
            'currency': 'USD',
            'order_id': '123456',
          },
        ),
        onPaymentComplete: (result) {
          if (result.status == 'success') {
            print('Payment successful!');
            print('Transaction ID: ${result.transactionId}');
            print('Amount: ${result.amount}');
          } else {
            print('Payment failed!');
          }
        },
      ),
    );
  }
}
```

### Advanced Usage

```dart
PaymentWebView(
  config: PaymentConfig(
    baseUrl: 'https://your-payment-gateway.com/pay',
    successUrlPattern: 'payment_success',
    failureUrlPattern: 'payment_failed',
    headers: {
      'Authorization': 'Bearer your-token',
      'Content-Type': 'application/json',
    },
    queryParams: {
      'amount': '100.00',
      'currency': 'USD',
      'order_id': '123456',
      'customer_id': 'CUST123',
    },
  ),
  onPaymentComplete: (result) {
    // Handle payment result
  },
  onError: (error) {
    // Handle errors
  },
  onPageStarted: () {
    // Page started loading
  },
  onPageFinished: () {
    // Page finished loading
  },
  loadingWidget: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
  ),
)
```

### Payment Result Handling

```dart
class PaymentResultHandler {
  static void handlePaymentResult(BuildContext context, PaymentResult result) {
    switch (result.status) {
      case 'success':
        _handleSuccess(context, result);
        break;
      case 'failed':
        _handleFailure(context, result);
        break;
      default:
        _handleUnknown(context, result);
    }
  }

  static void _handleSuccess(BuildContext context, PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${result.transactionId}'),
            Text('Amount: \$${result.amount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // ... other handler methods
}
```

## API Reference

### PaymentWebView

A widget that displays a payment webview with custom callbacks.

#### Properties

- `config` (required): The payment configuration
- `onPaymentComplete` (required): Callback when payment is completed
- `onError`: Callback when there's an error
- `onPageStarted`: Callback when the page starts loading
- `onPageFinished`: Callback when the page finishes loading
- `loadingWidget`: Custom loading widget

### PaymentConfig

Configuration for the payment webview.

#### Properties

- `baseUrl` (required): The base URL for the payment gateway
- `successUrlPattern`: The success URL pattern to match
- `failureUrlPattern`: The failure URL pattern to match
- `headers`: Additional headers to be sent with the request
- `queryParams`: Additional query parameters to be added to the URL

### PaymentResult

The result of a payment transaction.

#### Properties

- `status`: The status of the payment ('success' or 'failed')
- `transactionId`: The transaction ID if available
- `amount`: The payment amount if available

## Platform Support

Currently supports:
- Android
- iOS

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
