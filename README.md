# Payment WebView

A Flutter plugin for handling webviews with download and external app support. This plugin provides a simple way to integrate webviews into your Flutter app with support for file downloads, UPI payments, and external app launches.

## Features

- 🔄 General webview functionality
- 📥 File download support (PDF, DOC, XLS, ZIP, etc.)
- 💳 UPI payment handling
- 🔗 External app launching
- ⚡ Loading state management
- 🚫 Error handling
- 🎨 Customizable loading widget

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  payment_webview: ^0.0.1
```

## Usage

```dart
import 'package:payment_webview/payment_webview.dart';

// Inside your widget
PaymentWebView(
  url: 'https://your-url.com',
  onError: (error) {
    print('Error: $error');
  },
  loadingWidget: CircularProgressIndicator(), // Optional custom loading widget
)
```

## Features in Detail

### File Downloads
The plugin automatically handles file downloads for common file types:
- PDF (.pdf)
- Word documents (.doc, .docx)
- Excel spreadsheets (.xls, .xlsx)
- Archives (.zip, .rar)
- Any URL containing 'download'

Files are saved to:
- Android: `/storage/emulated/0/Download`
- iOS: Application Documents directory

### UPI Payments
UPI URLs are automatically detected and launched in the appropriate UPI app:
- Supports `upi://` scheme
- Supports `intent://` scheme for Android

### External Links
External links are opened in the device's default browser or appropriate app.

## Error Handling

The plugin provides error handling through the `onError` callback:

```dart
PaymentWebView(
  url: 'https://your-url.com',
  onError: (error) {
    // Handle errors like:
    // - Storage permission denied
    // - Download failures
    // - Web resource errors
    print('Error: $error');
  },
)
```

## Customization

### Loading Widget
You can customize the loading indicator:

```dart
PaymentWebView(
  url: 'https://your-url.com',
  loadingWidget: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading...'),
      ],
    ),
  ),
)
```

## Platform Support

- Android
- iOS

## Requirements

- Flutter 3.0.0 or higher
- Dart SDK 2.19.0 or higher

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
