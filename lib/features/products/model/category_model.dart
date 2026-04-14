import 'package:uae_ecom_project/features/products/model/product_model.dart';

class CategoryModel {
  final int id;
  final String name;
  final String? image;
  final String? description;
  final int? parent;

  CategoryModel({
    required this.id,
    required this.name,
    this.image,
    this.description,
    this.parent,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      image: json['image'] != null 
          ? ProductModel.getAbsoluteUrl(json['image'].toString()) 
          : null,
      description: json['description']?.toString(),
      parent: json['parent'] != null 
          ? int.tryParse(json['parent'].toString()) 
          : null,
    );
  }
}
