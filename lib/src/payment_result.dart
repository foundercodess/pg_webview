// src/payment_result.dart
/// The result of a payment transaction
class PaymentResult {
  /// The status of the payment ('success' or 'failed')
  final String status;
  
  /// The transaction ID if available
  final String? transactionId;
  
  /// The payment amount if available
  final double? amount;

  /// Creates a new [PaymentResult] instance.
  PaymentResult({
    required this.status,
    this.transactionId,
    this.amount,
  });

  /// Creates a [PaymentResult] from a JSON map.
  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      status: json['status'] as String,
      transactionId: json['transaction_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  /// Converts the [PaymentResult] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'transaction_id': transactionId,
      'amount': amount,
    };
  }
} 