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
  final String? preferredDeliverySlotName;
  final String? deliveryNotes;
  final String? customerName;
  final String? customerPhone;
  final double tipAmount;
  final List<StatusHistoryItem> statusHistory;
  final PaymentInfo? paymentInfo;
  final AddressModel? shippingAddressDetails;
  final String? paymentUrl;
  final double subTotal;
  final double deliveryCharge;
  final double discountAmount;
  final String? couponCode;
  final String? receiptPdf;
  final String? receiptRef;
  final String? receiptImage;
  final String? deliveryAssignmentStatus;
  final DateTime? deliveryAssignedAt;
  final DateTime? deliveryAcceptedAt;
  final DateTime? deliveryDeliveredAt;
  final DeliveryCancelRequest? deliveryCancelRequest;
  final String? profileMobileNumber;

  OrderModel({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
    this.preferredDeliveryDate,
    this.preferredDeliverySlot,
    this.preferredDeliverySlotName,
    this.deliveryNotes,
    this.customerName,
    this.customerPhone,
    this.tipAmount = 0.0,
    this.statusHistory = const [],
    this.paymentInfo,
    this.shippingAddressDetails,
    this.paymentUrl,
    this.subTotal = 0.0,
    this.deliveryCharge = 0.0,
    this.discountAmount = 0.0,
    this.couponCode,
    this.receiptPdf,
    this.receiptRef,
    this.receiptImage,
    this.deliveryAssignmentStatus,
    this.deliveryAssignedAt,
    this.deliveryAcceptedAt,
    this.deliveryDeliveredAt,
    this.deliveryCancelRequest,
    this.profileMobileNumber,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      items: ((json['items'] ?? json['order_items'] ?? json['order_item'] ?? json['shipment_manifest'] ?? json['manifest']) as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      totalPrice: double.tryParse((json['total_price'] ?? json['total_amount'])?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      paymentMethod: (json['payment']?['payment_method']?.toString() ?? 
                      json['payment_method']?.toString() ?? 
                      json['payment_type']?.toString() ?? 
                      json['gateway']?.toString() ?? 
                      'ZIINA').toString(),
      preferredDeliveryDate: json['preferred_delivery_date']?.toString(),
      preferredDeliverySlot: json['preferred_delivery_slot']?.toString(),
      preferredDeliverySlotName: json['preferred_delivery_slot_name']?.toString(),
      deliveryNotes: json['delivery_notes']?.toString(),
      customerName: (json['customer_name'] ?? json['customer'] ?? json['user_name'] ?? json['full_name'])?.toString() ??
          (json['shipping_address_details'] != null ? AddressModel.fromJson(json['shipping_address_details']).name : null),
      customerPhone: (
        json['customer_phone'] ?? 
        json['phone'] ?? 
        (json['customer'] is Map ? json['customer']['phone'] : null) ??
        (json['customer'] is Map ? json['customer']['mobile'] : null) ??
        (json['customer'] is Map ? json['customer']['mobile_number'] : null) ??
        (json['customer'] is Map ? json['customer']['phone_number'] : null) ??
        (json['user'] is Map ? json['user']['phone'] : null) ??
        (json['user'] is Map ? json['user']['mobile'] : null) ??
        (json['user'] is Map ? json['user']['mobile_number'] : null) ??
        (json['user'] is Map ? json['user']['phone_number'] : null) ??
        json['customer_phone_number'] ??
        json['user_phone'] ??
        json['account_phone'] ??
        json['mobile_number'] ??
        json['customer_mobile'] ??
        json['phone'] ??
        (json['billing_address'] is Map ? json['billing_address']['phone_number'] : null) ??
        (json['payment_details'] is Map ? json['payment_details']['phone'] : null)
      )?.toString(),
      tipAmount: double.tryParse(json['tip_amount']?.toString() ?? '0') ?? 0.0,
      statusHistory: (json['status_history'] as List<dynamic>?)
          ?.map((e) => StatusHistoryItem.fromJson(e))
          .toList() ?? [],
      paymentInfo: json['payment'] != null ? PaymentInfo.fromJson(json['payment']) : null,
      shippingAddressDetails: json['shipping_address_details'] != null 
          ? AddressModel.fromJson(json['shipping_address_details']) 
          : (json['shipping_address_summary'] != null 
              ? AddressModel.fromJson(json['shipping_address_summary']) 
              : null),
      paymentUrl: json['payment_url']?.toString(),
      subTotal: double.tryParse(json['sub_total']?.toString() ?? '0') ?? 0.0,
      deliveryCharge: double.tryParse(json['delivery_charge']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      couponCode: json['coupon_code']?.toString(),
      receiptPdf: json['receipt_pdf']?.toString(),
      receiptRef: json['receipt_ref']?.toString(),
      receiptImage: (json['delivery_proof']?['proof_image'] ?? json['receipt_image'])?.toString(),
      deliveryAssignmentStatus: json['delivery_assignment']?['status']?.toString(),
      deliveryAssignedAt: json['delivery_assignment']?['assigned_at'] != null 
          ? DateTime.parse(json['delivery_assignment']['assigned_at']) 
          : null,
      deliveryAcceptedAt: json['delivery_assignment']?['accepted_at'] != null 
          ? DateTime.parse(json['delivery_assignment']['accepted_at']) 
          : null,
      deliveryDeliveredAt: json['delivery_assignment']?['delivered_at'] != null 
          ? DateTime.parse(json['delivery_assignment']['delivered_at']) 
          : null,
      deliveryCancelRequest: json['delivery_cancel_request'] != null
          ? DeliveryCancelRequest.fromJson(json['delivery_cancel_request'])
          : null,
      profileMobileNumber: json['profile_mobile_number']?.toString(),
    );
  }
}

class DeliveryCancelRequest {
  final int id;
  final String reason;
  final String status;
  final String? reviewNotes;
  final DateTime requestedAt;
  final DateTime? reviewedAt;

  DeliveryCancelRequest({
    required this.id,
    required this.reason,
    required this.status,
    this.reviewNotes,
    required this.requestedAt,
    this.reviewedAt,
  });

  factory DeliveryCancelRequest.fromJson(Map<String, dynamic> json) {
    return DeliveryCancelRequest(
      id: json['id'] as int,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      reviewNotes: json['review_notes'] as String?,
      requestedAt: DateTime.parse(json['requested_at']),
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
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
        'id': int.tryParse(productData?.toString() ?? '0') ?? 0,
        'name': json['product_name']?.toString() ?? '',
        'image': json['product_image']?.toString(),
        // Use price from item if available
        'price': json['price'],
        'final_price': json['price'] ?? json['subtotal'],
      });
    }

    return OrderItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      product: product,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
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
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString(),
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
  final String? paymentUrl;

  PaymentInfo({
    this.transactionId,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
    this.paymentUrl,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      transactionId: json['transaction_id']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '',
      method: json['payment_method']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      paymentUrl: json['payment_url']?.toString(),
    );
  }
}
