// src/payment_config.dart
/// Configuration for the payment webview
class PaymentConfig {
  /// The base URL for the payment gateway
  final String baseUrl;

  /// The success URL pattern to match for successful payments
  final String successUrlPattern;

  /// The failure URL pattern to match for failed payments
  final String failureUrlPattern;

  /// Additional headers to be sent with the request
  final Map<String, String>? headers;

  /// Additional query parameters to be added to the URL
  final Map<String, String>? queryParams;

  const PaymentConfig({
    required this.baseUrl,
    this.successUrlPattern = 'payment_success',
    this.failureUrlPattern = 'payment_failed',
    this.headers,
    this.queryParams,
  });

  /// Creates a PaymentConfig from a JSON map
  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    return PaymentConfig(
      baseUrl: json['base_url'] as String,
      successUrlPattern: json['success_url_pattern'] as String? ?? 'payment_success',
      failureUrlPattern: json['failure_url_pattern'] as String? ?? 'payment_failed',
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      queryParams: (json['query_params'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  /// Converts the PaymentConfig to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'base_url': baseUrl,
      'success_url_pattern': successUrlPattern,
      'failure_url_pattern': failureUrlPattern,
      if (headers != null) 'headers': headers,
      if (queryParams != null) 'query_params': queryParams,
    };
  }

  /// Builds the complete payment URL with query parameters
  String buildPaymentUrl() {
    final uri = Uri.parse(baseUrl);
    final queryParameters = Map<String, String>.from(uri.queryParameters);
    if (queryParams != null) {
      queryParameters.addAll(queryParams!);
    }
    return uri.replace(queryParameters: queryParameters).toString();
  }
} 