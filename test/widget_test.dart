// test/widget_test.dart
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payment_webview/payment_webview.dart';
import 'package:webview_flutter/webview_flutter.dart';

// import 'package:customized_webview/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget( MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('PaymentWebView smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentWebView(
            url: 'https://example.com',
            onError: (error) {
              // Test error handling
              expect(error, isA<String>());
            },
          ),
        ),
      ),
    );

    // Verify that the WebView is rendered
    expect(find.byType(PaymentWebView), findsOneWidget);
    expect(find.byType(WebViewWidget), findsOneWidget);
  });

  testWidgets('PaymentWebView with custom loading widget', (WidgetTester tester) async {
    final customLoadingWidget = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentWebView(
            url: 'https://example.com',
            loadingWidget: customLoadingWidget,
            onError: (error) {
              // Test error handling
              expect(error, isA<String>());
            },
          ),
        ),
      ),
    );

    // Verify that the custom loading widget is rendered initially
    expect(find.byType(PaymentWebView), findsOneWidget);
    expect(find.byType(WebViewWidget), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });
}
