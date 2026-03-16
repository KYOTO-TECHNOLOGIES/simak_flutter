import 'package:uae_ecom_project/features/cart/model/cart_item_model.dart';

class CartModel {
  final List<CartItemModel> items;
  final double totalPrice;
  final int totalItems;

  CartModel({
    this.items = const [],
    this.totalPrice = 0.0,
    this.totalItems = 0,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    // Handle different possible keys for items
    final itemsData = json['items'] ?? json['cart_items'] ?? json['data']?['items'] ?? [];
    final itemsList = itemsData is List ? itemsData : [];
    
    return CartModel(
      items: itemsList.map((e) => CartItemModel.fromJson(e)).toList(),
      totalPrice: double.tryParse(json['total_price']?.toString() ?? json['total']?.toString() ?? '0.0') ?? 0.0,
      totalItems: json['total_items'] ?? json['count'] ?? itemsList.length,
    );
  }
}
