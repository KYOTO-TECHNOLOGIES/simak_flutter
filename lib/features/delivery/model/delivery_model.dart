import 'package:uae_ecom_project/features/orders/model/order_model.dart';

class DeliveryProfile {
  final int? id;
  final String? name;
  final bool isAvailable;
  final double rating;
  final double earningsTotal;
  final List<String> assignedEmirates;
  final List<String> assignedEmiratesDisplay;
  final String? vehicleNumber;
  final String? identityNumber;
  final String? emergencyContact;
  final String? notes;

  DeliveryProfile({
    this.id,
    this.name,
    required this.isAvailable,
    this.rating = 0.0,
    this.earningsTotal = 0.0,
    required this.assignedEmirates,
    required this.assignedEmiratesDisplay,
    this.vehicleNumber,
    this.identityNumber,
    this.emergencyContact,
    this.notes,
  });

  factory DeliveryProfile.fromJson(Map<String, dynamic> json) {
    return DeliveryProfile(
      id: json['id'],
      name: json['name'],
      isAvailable: json['is_available'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      earningsTotal: (json['earnings_total'] ?? 0.0).toDouble(),
      assignedEmirates: List<String>.from(json['assigned_emirates'] ?? []),
      assignedEmiratesDisplay: List<String>.from(json['assigned_emirates_display'] ?? []),
      vehicleNumber: json['vehicle_number'],
      identityNumber: json['identity_number'],
      emergencyContact: json['emergency_contact'],
      notes: json['notes'],
    );
  }
}

extension DeliveryProfileExt on DeliveryProfile {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_available': isAvailable,
      'rating': rating,
      'earnings_total': earningsTotal,
      'assigned_emirates': assignedEmirates,
      'assigned_emirates_display': assignedEmiratesDisplay,
      'vehicle_number': vehicleNumber,
      'identity_number': identityNumber,
      'emergency_contact': emergencyContact,
      'notes': notes,
    };
  }
}

class DeliveryDashboardData {
  final DeliveryProfile profile;
  final int assignedOrders;
  final int completedToday;
  final int pendingAssignedOrders;
  final int availableOrdersInRegion;
  final int completedTotal;
  final List<OrderModel> recentAssignments;

  DeliveryDashboardData({
    required this.profile,
    required this.assignedOrders,
    required this.completedToday,
    required this.pendingAssignedOrders,
    required this.availableOrdersInRegion,
    required this.completedTotal,
    required this.recentAssignments,
  });

  factory DeliveryDashboardData.fromJson(Map<String, dynamic> json) {
    final kpis = json['kpis'] as Map<String, dynamic>? ?? {};
    final recentOrders = (json['recent_assigned_orders'] ?? json['recent_assignments']) as List? ?? [];
    
    return DeliveryDashboardData(
      profile: DeliveryProfile.fromJson(json['delivery_boy'] ?? json['profile'] ?? {}),
      assignedOrders: kpis['assigned_orders'] ?? json['assigned_orders'] ?? 0,
      completedToday: kpis['completed_today'] ?? json['completed_today'] ?? 0,
      pendingAssignedOrders: kpis['pending_assigned_orders'] ?? json['pending_assigned_orders'] ?? 0,
      availableOrdersInRegion: kpis['available_orders_in_region'] ?? json['available_orders_in_region'] ?? 0,
      completedTotal: kpis['completed_total'] ?? json['completed_total'] ?? 0,
      recentAssignments: recentOrders
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeliveryAssignment {
  final int id;
  final int orderId;
  final int deliveryBoyId;
  final String status;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final String? notes;

  DeliveryAssignment({
    required this.id,
    required this.orderId,
    required this.deliveryBoyId,
    required this.status,
    this.assignedAt,
    this.acceptedAt,
    this.deliveredAt,
    this.notes,
  });

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) {
    return DeliveryAssignment(
      id: json['id'],
      orderId: json['order'],
      deliveryBoyId: json['delivery_boy'],
      status: json['status'],
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at']).toLocal() : null,
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']).toLocal() : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']).toLocal() : null,
      notes: json['notes'],
    );
  }
}

class DeliveryProof {
  final int id;
  final int orderId;
  final String proofImage;
  final String? signatureName;
  final String? notes;
  final DateTime createdAt;

  DeliveryProof({
    required this.id,
    required this.orderId,
    required this.proofImage,
    this.signatureName,
    this.notes,
    required this.createdAt,
  });

  factory DeliveryProof.fromJson(Map<String, dynamic> json) {
    return DeliveryProof(
      id: json['id'],
      orderId: json['order'],
      proofImage: json['proof_image'],
      signatureName: json['signature_name'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

class DeliveryCancellationRequest {
  final int id;
  final int orderId;
  final String reason;
  final String status; // PENDING, APPROVED, REJECTED
  final String? reviewNotes;
  final DateTime requestedAt;

  DeliveryCancellationRequest({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.status,
    this.reviewNotes,
    required this.requestedAt,
  });

  factory DeliveryCancellationRequest.fromJson(Map<String, dynamic> json) {
    return DeliveryCancellationRequest(
      id: json['id'],
      orderId: json['order'],
      reason: json['reason'],
      status: json['status'],
      reviewNotes: json['review_notes'],
      requestedAt: DateTime.parse(json['requested_at']).toLocal(),
    );
  }
}
