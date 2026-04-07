class PaymentModel {
  final int paymentId;
  final int orderId;
  final int? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String amount;
  final String paymentMethod;
  final String? paymentMethodDisplay;
  final String status;
  final String? paymentStatusDisplay;
  final String? orderStatus;
  final String? transactionId;
  final String? ziinaPaymentIntentId;
  final String? transactionDate;
  final String? updatedDate;
  final Map<String, dynamic>? providerResponse;
  final String? paymentUrl;

  PaymentModel({
    required this.paymentId,
    required this.orderId,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.amount,
    required this.paymentMethod,
    this.paymentMethodDisplay,
    required this.status,
    this.paymentStatusDisplay,
    this.orderStatus,
    this.transactionId,
    this.ziinaPaymentIntentId,
    this.transactionDate,
    this.updatedDate,
    this.providerResponse,
    this.paymentUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['payment_id'] as int? ?? json['id'] as int? ?? 0,
      orderId: json['order_id'] as int? ?? json['order'] as int? ?? 0,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      amount: json['amount']?.toString() ?? '0.00',
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentMethodDisplay: json['payment_method_display'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      paymentStatusDisplay: json['payment_status_display'] as String?,
      orderStatus: json['order_status'] as String?,
      transactionId: json['transaction_id'] as String?,
      ziinaPaymentIntentId: json['ziina_payment_intent_id'] as String?,
      transactionDate: json['transaction_date'] as String? ?? json['created_at'] as String?,
      updatedDate: json['updated_date'] as String? ?? json['updated_at'] as String?,
      providerResponse: json['provider_response'] as Map<String, dynamic>?,
      paymentUrl: json['payment_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'order_id': orderId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_method_display': paymentMethodDisplay,
      'status': status,
      'payment_status_display': paymentStatusDisplay,
      'order_status': orderStatus,
      'transaction_id': transactionId,
      'ziina_payment_intent_id': ziinaPaymentIntentId,
      'transaction_date': transactionDate,
      'updated_date': updatedDate,
      'provider_response': providerResponse,
      'payment_url': paymentUrl,
    };
  }

  bool get isPaid => status.toUpperCase() == 'PAID' || status.toUpperCase() == 'COMPLETED' || status.toUpperCase() == 'SUCCESS';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isFailed => status.toUpperCase() == 'FAILED' || status.toUpperCase() == 'CANCELLED';
}
