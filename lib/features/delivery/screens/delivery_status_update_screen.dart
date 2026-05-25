import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';

class DeliveryStatusUpdateScreen extends StatefulWidget {
  final OrderModel order;
  final String? initialStatus;
  
  const DeliveryStatusUpdateScreen({super.key, required this.order, this.initialStatus});

  @override
  State<DeliveryStatusUpdateScreen> createState() => _DeliveryStatusUpdateScreenState();
}

class _DeliveryStatusUpdateScreenState extends State<DeliveryStatusUpdateScreen> {
  String? _selectedStatus;
  File? _proofImage;
  final _notesController = TextEditingController();
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
      availableTransitions = ['SHIPPED', 'DELIVERED'];
    } else if (currentStatus == 'SHIPPED') {
      availableTransitions = ['DELIVERED'];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Update Order #${widget.order.id}',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Next Status',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              
              if (widget.initialStatus == null) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: availableTransitions.map((status) {
                    final isSelected = _selectedStatus == status;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedStatus = _selectedStatus == status ? null : status);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatStatus(status),
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (_selectedStatus == 'DELIVERED') ...[
                const SizedBox(height: 32),
                Text(
                  'Delivery Proof (Required)',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                    if (image != null) setState(() => _proofImage = File(image.path));
                  },
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _proofImage != null ? Colors.transparent : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: _proofImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_proofImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, color: Colors.grey.shade400, size: 40),
                              const SizedBox(height: 12),
                              Text('Tap to take photo', style: GoogleFonts.outfit(color: Colors.grey.shade600)),
                            ],
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Text(
                'Internal Notes',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Add any extra details for this update...',
                  hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade400),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                maxLines: 4,
                style: GoogleFonts.outfit(),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedStatus == null || 
                         (controller.isActionLoading) ||
                         (_selectedStatus == 'DELIVERED' && _proofImage == null))
                  ? null
                  : () async {
                      final success = await context.read<DeliveryController>().updateStatus(
                        widget.order.id,
                        _selectedStatus!,
                        proofImage: _proofImage,
                        notes: _notesController.text,
                      );

                      final errorMsg = controller.error;

                      if (!context.mounted) return;

                      if (success) {
                        Navigator.pop(context);

                        String message = 'Status updated successfully!';
                        if (_selectedStatus == 'SHIPPED') message = 'Order marked as Shipped';
                        if (_selectedStatus == 'DELIVERED') message = 'Order delivered successfully!';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                        // Refresh orders
                        final auth = context.read<AuthController>();
                        if (auth.currentUser?.id != null) {
                          context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $errorMsg')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: controller.isActionLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'CONFIRM UPDATE',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'N/A';
    return status.replaceAll('_', ' ').toUpperCase();
  }
}
