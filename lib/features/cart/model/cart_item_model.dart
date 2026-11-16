import 'package:uae_ecom_project/features/products/model/product_model.dart';

class CartItemModel {
  final int id;
  final ProductModel product;
  final int quantity;
  final double subtotal;

  final int? preparationSpecificationId;
  final String? _preparationSpecificationName;
  final PreparationSpecification? preparationSpecification;
  String? get preparationSpecificationName =>
      preparationSpecification?.name ?? _preparationSpecificationName;
  final List<CartAddonModel> addons;
  final String? preparationInstructions;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.subtotal,
    this.preparationSpecificationId,
    String? preparationSpecificationName,
    this.preparationSpecification,
    this.addons = const [],
    this.preparationInstructions,
  }) : _preparationSpecificationName = preparationSpecificationName;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Robust mapping for product data
    Map<String, dynamic> productData = {};
    if (json['product'] is Map<String, dynamic>) {
      productData = Map<String, dynamic>.from(json['product']);
    } else if (json['product_details'] is Map<String, dynamic>) {
      productData = Map<String, dynamic>.from(json['product_details']);
    } else {
      // If flat structure, pick relevant fields
      productData = {
        'id': json['product_id'] ?? json['id'],
        'name': json['product_name'] ?? json['name'] ?? json['title'],
        'image': json['product_image'] ?? json['image'] ?? json['thumbnail'],
        'price': json['price'] ?? json['final_price'],
        'final_price': json['final_price'] ?? json['price'],
      };
    }

    final product = ProductModel.fromJson(productData);
    final quantity = json['quantity'] ?? 1;

    // Calculate subtotal if not provided by API
    final subtotalRaw = double.tryParse(json['subtotal']?.toString() ?? '');
    final subtotal = subtotalRaw ?? (product.finalPrice * quantity);

    final preparationSpecDetails =
        json['preparation_specification_details'] as Map<String, dynamic>?;
    final preparationInstructions =
        json['preparation_instructions']?.toString();

    return CartItemModel(
      id: json['id'] ?? 0,
      product: product,
      quantity: quantity,
      subtotal: subtotal,
      preparationSpecificationId:
          json['preparation_specification'] != null
              ? int.tryParse(json['preparation_specification'].toString())
              : null,
      preparationSpecificationName: preparationSpecDetails?['name']?.toString(),
      preparationInstructions: preparationInstructions,
      preparationSpecification:
          preparationSpecDetails == null
              ? null
              : PreparationSpecification.fromJson(preparationSpecDetails),
      addons:
          (json['addons'] as List<dynamic>? ?? [])
              .map((e) => CartAddonModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }
}

class CartAddonModel {
  final ProductAddon addon;
  final int quantity;
  final double lineExtraPrice;

  CartAddonModel({
    required this.addon,
    required this.quantity,
    required this.lineExtraPrice,
  });

  factory CartAddonModel.fromJson(Map<String, dynamic> json) {
    return CartAddonModel(
      addon: ProductAddon.fromJson(
        Map<String, dynamic>.from(json['addon_details'] as Map? ?? {}),
      ),
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      lineExtraPrice:
          double.tryParse(json['line_extra_price']?.toString() ?? '0') ?? 0,
    );
  }
}
