import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

class PrepSelectionSheet extends StatefulWidget {
  final ProductModel product;
  final Function(int specId, String instructions) onSelected;

  const PrepSelectionSheet({
    super.key,
    required this.product,
    required this.onSelected,
  });

  @override
  State<PrepSelectionSheet> createState() => _PrepSelectionSheetState();
}

class _PrepSelectionSheetState extends State<PrepSelectionSheet> {
  PreparationSpecification? _selectedSpec;
  final TextEditingController _instructionsController = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                tr(context, 'preparation_cleaning'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(context, 'please_select_preparation'),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              
              if (_showError) ...[
                const SizedBox(height: 12),
                Text(
                  tr(context, 'please_select_preparation'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Options List
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.product.preparationSpecifications.map((spec) {
                      final isSelected = _selectedSpec?.id == spec.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSpec = spec;
                            _showError = false;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.05) : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (spec.image != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CustomImage(
                                    spec.image!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            spec.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? AppColors.primary : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (spec.extraPrice > 0) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F7FA), // Light cyan
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '+AED ${spec.extraPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF00ACC1), // Cyan text
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (spec.description != null)
                                      Text(
                                        spec.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Special Instructions
              if (_selectedSpec != null) ...[
                const SizedBox(height: 16),
                Text(
                  tr(context, 'special_instructions_optional'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _instructionsController,
                  decoration: InputDecoration(
                    hintText: tr(context, 'special_instructions_hint'),
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedSpec == null) {
                      setState(() => _showError = true);
                      return;
                    }
                    widget.onSelected(_selectedSpec!.id, _instructionsController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    tr(context, 'confirm'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
