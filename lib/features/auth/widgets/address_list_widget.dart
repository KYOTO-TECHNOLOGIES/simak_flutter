import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/auth/controller/address_controller.dart';
import 'package:uae_ecom_project/features/auth/model/address_model.dart';
import 'package:uae_ecom_project/features/auth/widgets/add_address_dialog.dart';

class AddressListWidget extends StatelessWidget {
  final Function(AddressModel) onAddressSelected;
  final AddressModel? selectedAddress;

  const AddressListWidget({
    super.key,
    required this.onAddressSelected,
    this.selectedAddress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addressController = context.watch<AddressController>();
    final addresses = addressController.addresses;

    if (addressController.isLoading && addresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              'No addresses found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddAddressDialog(context),
              icon: const Icon(Icons.add),
              label: Text(tr(context, 'add_new_address')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'deliver_to'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _showAddAddressDialog(context),
              child: Text(tr(context, 'add_new_address')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            final address = addresses[index];
            final isSelected = selectedAddress?.id == address.id;

            return GestureDetector(
              onTap: () => onAddressSelected(address),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: isSelected ? 6 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address.type?.toUpperCase() ?? 'OTHER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected ? AppColors.primary : Colors.grey.shade600,
                                ),
                              ),
                              if (address.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green.shade100, width: 0.5),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (address.name != null && address.name!.isNotEmpty)
                            Text(
                              address.name!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            address.line1 ?? '',
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                          ),
                          if (address.line2 != null && address.line2!.isNotEmpty)
                            Text(address.line2!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          Text(
                            '${address.city}, ${address.state}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          if (address.phoneNumber != null && address.phoneNumber!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Phone: ${address.phoneNumber}',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (address.landmark != null && address.landmark!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Landmark: ${address.landmark}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isSelected && address.id != null)
                      IconButton(
                        onPressed: () => addressController.deleteAddress(address.id!),
                        icon: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddAddressDialog(),
    );
  }
}
