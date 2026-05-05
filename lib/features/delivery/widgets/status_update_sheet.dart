import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';

class StatusUpdateSheet extends StatefulWidget {
  final OrderModel order;
  final String? initialStatus;
  
  const StatusUpdateSheet({super.key, required this.order, this.initialStatus});

  @override
  State<StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<StatusUpdateSheet> {
  String? _selectedStatus;
  File? _proofImage;
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveryController>();
    final currentStatus = widget.order.status;

    List<String> availableTransitions = [];
    if (currentStatus == 'PAID' || currentStatus == 'PROCESSING') {
      availableTransitions = ['SHIPPED', 'CANCELLED'];
    } else if (currentStatus == 'SHIPPED') {
      availableTransitions = ['DELIVERED', 'CANCELLED'];
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Update Order Status',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the next status for order #${widget.order.id}',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          Wrap(
            spacing: 12,
            children: availableTransitions.map((status) {
              final isSelected = _selectedStatus == status;
              return ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedStatus = selected ? status : null);
                },
                selectedColor: AppColors.actionBlue.withOpacity(0.1),
                labelStyle: GoogleFonts.outfit(
                  color: isSelected ? AppColors.actionBlue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),

          if (_selectedStatus == 'DELIVERED') ...[
            const SizedBox(height: 24),
            Text(
              'Delivery Proof (Required)',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (image != null) setState(() => _proofImage = File(image.path));
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_proofImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Take Photo', style: GoogleFonts.outfit(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
          ],

          if (_selectedStatus == 'CANCELLED') ...[
            const SizedBox(height: 24),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'e.g. Customer unreachable',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],

          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Internal Notes',
              hintText: 'Optional notes for this update',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_selectedStatus == null || 
                         (controller.isActionLoading) ||
                         (_selectedStatus == 'DELIVERED' && _proofImage == null) ||
                         (_selectedStatus == 'CANCELLED' && _reasonController.text.isEmpty))
                  ? null
                  : () async {
                      final success = await context.read<DeliveryController>().updateStatus(
                        widget.order.id,
                        _selectedStatus!,
                        proofImage: _proofImage,
                        cancelReason: _reasonController.text,
                        notes: _notesController.text,
                      );

                      if (!mounted) return;
                      
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_selectedStatus == 'CANCELLED' 
                            ? 'Cancellation request submitted' 
                            : 'Status updated successfully!')),
                        );
                        // Refresh orders
                        final auth = context.read<AuthController>();
                        if (auth.currentUser?.id != null) {
                          context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
                        }
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${controller.error}')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: controller.isActionLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _selectedStatus == 'CANCELLED' ? 'REQUEST CANCELLATION' : 'CONFIRM UPDATE',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
