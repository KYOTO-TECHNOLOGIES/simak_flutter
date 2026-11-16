import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:uae_ecom_project/features/cart/model/cart_item_model.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

class CartAddonsSheet extends StatefulWidget {
  final CartItemModel item;
  const CartAddonsSheet({super.key, required this.item});

  @override
  State<CartAddonsSheet> createState() => _CartAddonsSheetState();
}

class _CartAddonsSheetState extends State<CartAddonsSheet> {
  late final Map<int, int> quantities = {
    for (final selection in widget.item.addons)
      selection.addon.id: selection.quantity,
  };
  late final Map<int, ProductAddon> addons = {
    for (final selection in widget.item.addons)
      selection.addon.id: selection.addon,
    for (final addon in widget.item.product.addons.where((a) => a.isActive))
      addon.id: addon,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'edit_addons'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(tr(context, 'addons_independent_hint')),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final addon in addons.values)
                    Builder(
                      builder: (context) {
                        final quantity = quantities[addon.id] ?? 0;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              addon.image != null &&
                                      addon.image!.trim().isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CustomImage(
                                      addon.image!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : null,
                          title: Text(addon.name),
                          subtitle: Text(
                            'AED ${addon.extraPrice.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: tr(context, 'decrease_addon'),
                                onPressed:
                                    quantity > 0
                                        ? () => setState(
                                          () =>
                                              quantities[addon.id] =
                                                  quantity - 1,
                                        )
                                        : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$quantity'),
                              IconButton(
                                tooltip: tr(context, 'increase_addon'),
                                onPressed:
                                    addon.isActive &&
                                            (addon.maxQuantity <= 0 ||
                                                quantity < addon.maxQuantity)
                                        ? () => setState(
                                          () =>
                                              quantities[addon.id] =
                                                  quantity + 1,
                                        )
                                        : null,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, quantities),
                child: Text(tr(context, 'save_addons')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
