import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/features/products/products_page.dart';
import 'package:uae_ecom_project/features/products/service/product_service.dart';

class GrillFryCategoryPage extends StatefulWidget {
  const GrillFryCategoryPage({super.key});

  @override
  State<GrillFryCategoryPage> createState() => _GrillFryCategoryPageState();
}

class _GrillFryCategoryPageState extends State<GrillFryCategoryPage> {
  bool _loading = true;
  bool _failed = false;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategory());
  }

  Future<void> _loadCategory() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final categories = await ProductService().fetchCategories();
      if (!mounted) return;
      final matches = categories.where(
        (c) => c.name.toUpperCase().contains('GRILL'),
      );
      _found = matches.isNotEmpty;
      if (_found) {
        context.read<ProductController>().selectCategory(matches.first.name);
      }
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'cat_grill_and_fry'))),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _failed
              ? Center(
                child: TextButton(
                  onPressed: _loadCategory,
                  child: Text(tr(context, 'retry')),
                ),
              )
              : _found
              ? const ProductsPage()
              : Center(child: Text(tr(context, 'no_products_found'))),
    );
  }
}
