import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/auth/model/address_model.dart';

class OrderModel {
  final int id;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String paymentMethod;
  final String? preferredDeliveryDate;
  final String? preferredDeliverySlot;
  final String? deliveryNotes;
  final double tipAmount;
  final List<StatusHistoryItem> statusHistory;
  final PaymentInfo? paymentInfo;
  final AddressModel? shippingAddressDetails;

  OrderModel({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
    this.preferredDeliveryDate,
    this.preferredDeliverySlot,
    this.deliveryNotes,
    this.tipAmount = 0.0,
    this.statusHistory = const [],
    this.paymentInfo,
    this.shippingAddressDetails,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      totalPrice: double.tryParse((json['total_price'] ?? json['total_amount'])?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      paymentMethod: json['payment_method'] ?? '',
      preferredDeliveryDate: json['preferred_delivery_date'],
      preferredDeliverySlot: json['preferred_delivery_slot'],
      deliveryNotes: json['delivery_notes'],
      tipAmount: double.tryParse(json['tip_amount']?.toString() ?? '0') ?? 0.0,
      statusHistory: (json['status_history'] as List<dynamic>?)
          ?.map((e) => StatusHistoryItem.fromJson(e))
          .toList() ?? [],
      paymentInfo: json['payment'] != null ? PaymentInfo.fromJson(json['payment']) : null,
      shippingAddressDetails: json['shipping_address_details'] != null 
          ? AddressModel.fromJson(json['shipping_address_details']) 
          : null,
    );
  }
}

class OrderItem {
  final int id;
  final ProductModel product;
  final int quantity;
  final double priceAtOrder;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.priceAtOrder,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'];
    ProductModel product;

    if (productData is Map<String, dynamic>) {
      product = ProductModel.fromJson(productData);
    } else {
      // Handle flattened structure or just ID from orders API
      product = ProductModel.fromJson({
        'id': productData is int ? productData : 0,
        'name': json['product_name'] ?? '',
        'image': json['product_image'],
        // Use price from item if available
        'price': json['price'],
        'final_price': json['price'] ?? json['subtotal'],
      });
    }

    return OrderItem(
      id: json['id'] ?? 0,
      product: product,
      quantity: json['quantity'] ?? 1,
      priceAtOrder: double.tryParse(json['price']?.toString() ?? json['unit_price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class StatusHistoryItem {
  final String status;
  final String? notes;
  final DateTime createdAt;

  StatusHistoryItem({
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      status: json['status'] ?? '',
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class PaymentInfo {
  final String? transactionId;
  final double amount;
  final String status;
  final String method;
  final DateTime createdAt;

  PaymentInfo({
    this.transactionId,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      transactionId: json['transaction_id'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? '',
      method: json['payment_method'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
