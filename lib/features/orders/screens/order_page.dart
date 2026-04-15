import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/auth/controller/address_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/checkout_controller.dart';
import 'package:uae_ecom_project/features/auth/widgets/address_list_widget.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/widgets/otp_verification_dialog.dart';
import 'package:uae_ecom_project/features/products/screens/product_detail_screen.dart';
import 'package:uae_ecom_project/features/payment/screens/payment_webview_screen.dart';

class OrderPage extends StatefulWidget {
  final ProductModel product;
  final int quantity;

  const OrderPage({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  bool _isCustomTip = false;
  final TextEditingController _customTipController = TextEditingController();
  final TextEditingController couponController = TextEditingController();

  @override
  void dispose() {
    _customTipController.dispose();
    couponController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    // Reset checkout state when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final checkout = context.read<CheckoutController>();
      checkout.reset();
      checkout.fetchAvailableCoupons();
      
      // Auto-select default address if available
      final addressController = context.read<AddressController>();
      if (addressController.selectedAddress != null && addressController.selectedAddress!.id != null) {
        checkout.selectAddress(addressController.selectedAddress!.id!);
      }

      // Fetch estimated delivery
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final displayProduct = args?['product'] as ProductModel? ?? widget.product;
      final displayQuantity = args?['quantity'] as int? ?? widget.quantity;
      final isCartMode = args?['isCartMode'] as bool? ?? (displayProduct.id == 0);

      checkout.fetchEstimatedDelivery(
        product: isCartMode ? null : displayProduct,
        quantity: isCartMode ? null : displayQuantity,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkoutController = context.watch<CheckoutController>();
    final addressController = context.watch<AddressController>();
    
    // Extract arguments if passed via transparent routing
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final displayProduct = args?['product'] as ProductModel? ?? widget.product;
    final displayQuantity = args?['quantity'] as int? ?? widget.quantity;
    final isCartMode = args?['isCartMode'] as bool? ?? (displayProduct.id == 0);
    final cartController = context.watch<CartController>();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(context, 'order_summary'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (checkoutController.currentStep != CheckoutStep.address) {
              checkoutController.previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // ── Stepper Header ───────────────────────────
          _buildStepper(context, checkoutController.currentStep),
          
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildCurrentStepView(
                  context, 
                  checkoutController, 
                  addressController, 
                  cartController,
                  displayProduct, 
                  displayQuantity,
                  isCartMode,
                  theme,
                ),
              ),
            ),
          ),
          
          // ── Bottom Action Bar ───────────────────────────
          _buildBottomAction(
            context, 
            checkoutController, 
            isCartMode ? null : displayProduct, 
            isCartMode ? null : displayQuantity,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(BuildContext context, CheckoutStep currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepCircle(context, 1, tr(context, 'address'), currentStep == CheckoutStep.address, currentStep != CheckoutStep.address),
          _buildStepDivider(currentStep != CheckoutStep.address),
          _buildStepCircle(context, 2, tr(context, 'order_summary'), currentStep == CheckoutStep.summary, currentStep == CheckoutStep.payment),
          _buildStepDivider(currentStep == CheckoutStep.payment),
          _buildStepCircle(context, 3, tr(context, 'payment'), currentStep == CheckoutStep.payment, false),
        ],
      ),
    );
  }

  Widget _buildStepCircle(BuildContext context, int step, String label, bool isActive, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primary : (isActive ? AppColors.primary : Colors.grey[300]),
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: AppColors.primary, width: 2) : null,
          ),
          child: Center(
            child: isCompleted 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '$step',
                  style: TextStyle(
                    color: (isActive || isCompleted) ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isCompleted ? AppColors.primary : Colors.grey[300],
      ),
    );
  }

  Widget _buildCurrentStepView(
    BuildContext context, 
    CheckoutController checkout, 
    AddressController address,
    CartController cart,
    ProductModel displayProduct,
    int displayQuantity,
    bool isCartMode,
    ThemeData theme,
  ) {
    switch (checkout.currentStep) {
      case CheckoutStep.address:
        return Column(
          children: [
            AddressListWidget(
              selectedAddress: address.addresses.where((a) => a.id == checkout.selectedAddressId).firstOrNull,
              onAddressSelected: (addr) {
                checkout.selectAddress(addr.id!);
                address.selectAddress(addr);
              },
            ),
            const SizedBox(height: 24),
            _buildDeliveryPreferences(context, checkout, theme),
          ],
        );
      case CheckoutStep.summary:
        final selectedAddr = address.selectedAddress;
        
        // Initial summary fetch if needed
        if (checkout.summaryData == null && !checkout.isLoading && !checkout.summaryFetchAttempted && selectedAddr != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             checkout.fetchCheckoutSummary(
              product: isCartMode ? null : displayProduct,
              quantity: isCartMode ? null : displayQuantity,
             );
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deliver to Section
            _buildSectionHeader(context, tr(context, 'deliver_to'), onAction: () => checkout.setStep(CheckoutStep.address)),
            if (selectedAddr != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${selectedAddr.label?.toUpperCase() ?? 'HOME'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 10),
                          ),
                        ),
                        if (selectedAddr.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tr(context, 'default').toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 10),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '${selectedAddr.city}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('${selectedAddr.addressLine1}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (selectedAddr.addressLine2 != null && selectedAddr.addressLine2!.isNotEmpty)
                      Text('${selectedAddr.addressLine2}', style: TextStyle(color: Colors.grey[600])),
                    if (selectedAddr.landmark != null && selectedAddr.landmark!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${tr(context, 'landmark')}: ${selectedAddr.landmark}', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Product Section
            _buildSectionHeader(context, tr(context, 'order_summary')),
            if (isCartMode && cart.cart != null)
              ...cart.cart!.items.map((item) => _buildSummaryItem(context, item.product, item.quantity, theme))
            else if (!isCartMode)
              _buildSummaryItem(context, displayProduct, displayQuantity, theme),
            
            const SizedBox(height: 24),
            
            _buildTipSection(context, checkout, theme),
            
            const SizedBox(height: 24),
            
            // Phone Verification Warning
            _buildVerificationWarning(context, displayProduct, displayQuantity, isCartMode, theme),
            
            // Coupon Section
            _buildCouponSection(context, checkout, cart, displayProduct, displayQuantity, isCartMode, theme),
            
            const SizedBox(height: 24),
            
            // Price Details Block
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context, 
                    tr(context, 'subtotal'), 
                    'AED ${checkout.hasSummary ? checkout.summarySubtotal.toStringAsFixed(2) : (isCartMode ? cart.totalPrice : displayProduct.finalPrice * displayQuantity).toStringAsFixed(2)}'
                  ),
                  _buildDetailRow(
                    context, 
                    tr(context, 'discount'), 
                    'AED ${checkout.hasSummary ? checkout.summaryDiscount.toStringAsFixed(2) : '0.00'}',
                    valueColor: Colors.green
                  ),
                  _buildDetailRow(
                    context, 
                    tr(context, 'shipping'), 
                    'AED ${checkout.hasSummary ? checkout.summaryDeliveryCharge.toStringAsFixed(2) : '0.00'}'
                  ),
                  _buildDetailRow(
                    context, 
                    tr(context, 'tip'), 
                    'AED ${(checkout.hasSummary ? checkout.summaryTip : checkout.tipAmount).toStringAsFixed(2)}'
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildDetailRow(
                    context,
                    tr(context, 'total'),
                    'AED ${checkout.hasSummary ? checkout.summaryTotal.toStringAsFixed(2) : ((isCartMode ? cart.totalPrice : displayProduct.finalPrice * displayQuantity) + checkout.tipAmount).toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        );
      case CheckoutStep.payment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, tr(context, 'payment_method')),
            _buildPaymentOption(
              context, 
              checkout, 
              tr(context, 'payment_cod'), 
              Icons.delivery_dining_outlined, 
              tr(context, 'payment_cod_desc'),
              isAvailable: false,
            ),
            _buildPaymentOption(
              context, 
              checkout, 
              tr(context, 'payment_online_telr'), 
              Icons.credit_card_outlined, 
              tr(context, 'payment_online_telr_desc'),
              isAvailable: true,
            ),
          ],
        );
    }
  }

  Widget _buildDeliveryPreferences(BuildContext context, CheckoutController checkout, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 18, color: Colors.orange.shade300),
              const SizedBox(width: 8),
              Text(tr(context, 'checkout_delivery_preferences'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Estimated Delivery Window Box (Orange)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE7C2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr(context, 'checkout_estimated_delivery_window').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (checkout.isLoadingDelivery)
                  const Text(
                    'Calculating...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                  )
                else if (checkout.minDeliveryDate != null) ...[
                  Text(
                    '${checkout.maxDeliveryDays ?? 0} days delivery time',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minimum delivery date is in ${checkout.minDeliveryDate!.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays} days',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(
                    tr(context, 'checkout_delivery_min_date_tomorrow'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: tr(context, 'checkout_preferred_date').toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        children: [
                          const TextSpan(text: '*', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final minDate = checkout.minDeliveryDate ?? DateTime(now.year, now.month, now.day + 1);
                        
                        // Ensure initial date is safe
                        DateTime initialDate = minDate;
                        if (checkout.deliveryDate != null && !checkout.deliveryDate!.isBefore(minDate)) {
                          initialDate = checkout.deliveryDate!;
                        }

                        final date = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: minDate,
                          lastDate: minDate.add(Duration(days: checkout.maxDeliveryDays ?? 7)),
                        );
                        if (date != null) checkout.setDeliveryPreferences(date: date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                checkout.deliveryDate == null 
                                  ? 'Pick a date' 
                                  : '${checkout.deliveryDate!.day.toString().padLeft(2, '0')} / ${checkout.deliveryDate!.month.toString().padLeft(2, '0')} / ${checkout.deliveryDate!.year}',
                                style: TextStyle(
                                  color: checkout.deliveryDate == null ? Colors.grey : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: tr(context, 'checkout_delivery_slot').toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        children: [
                          const TextSpan(text: '*', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              checkout.deliverySlotName ?? tr(context, 'checkout_select_slot'),
                              style: TextStyle(
                                fontSize: 12,
                                color: checkout.deliverySlotName == null ? Colors.grey : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (checkout.deliveryDate != null) ...[
            const SizedBox(height: 16),
            if (checkout.isLoadingSlots)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (checkout.availableSlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No delivery slots available for this date. Please select another date.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: checkout.availableSlots.map((slot) {
                  final isSelected = checkout.deliverySlotId == slot.id;
                  return InkWell(
                    onTap: () {
                      checkout.setDeliveryPreferences(
                        slotId: slot.id,
                        slotName: slot.name,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ] : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slot.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${slot.startTimeDisplay} - ${slot.endTimeDisplay}',
                            style: TextStyle(
                              color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
          const SizedBox(height: 24),
          Text(tr(context, 'checkout_delivery_notes').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          TextField(
            onChanged: (v) => checkout.setDeliveryPreferences(notes: v),
            decoration: InputDecoration(
              hintText: tr(context, 'checkout_notes_hint'),
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Order Quantity Info Box (Blue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD6E9FF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFF3393FF)),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11, color: Color(0xFF3393FF), height: 1.4),
                      children: [
                        TextSpan(text: tr(context, 'checkout_delivery_time_based_on'), style: const TextStyle(color: Color(0xFF3393FF))),
                        TextSpan(
                          text: tr(context, 'checkout_order_quantity'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(text: tr(context, 'checkout_larger_orders_info')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection(BuildContext context, CheckoutController checkout, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delivery_dining_outlined, size: 20, color: Colors.cyan),
              ),
              const SizedBox(width: 12),
              Text(
                tr(context, 'checkout_add_tip'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTipInfo(context, checkout),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTipOption(checkout, 0.0, tr(context, 'checkout_no_tip')),
                _buildTipOption(checkout, 1.0, tr(context, 'checkout_tip_1')),
                _buildTipOption(checkout, 3.0, tr(context, 'checkout_tip_3')),
                _buildTipOption(checkout, 5.0, tr(context, 'checkout_tip_5')),
                _buildCustomTipButton(checkout),
              ],
            ),
          ),
          if (_isCustomTip) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(tr(context, 'currency_aed'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                const SizedBox(width: 12),
                Container(
                  width: 120,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customTipController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final amount = double.tryParse(v) ?? 0.0;
                            checkout.setTipAmount(amount);
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final current = double.tryParse(_customTipController.text) ?? 0.0;
                          final next = current == 0.0 ? 1.0 : current + 0.5;
                          _customTipController.text = next.toStringAsFixed(1);
                          checkout.setTipAmount(next);
                        },
                        child: Icon(Icons.add, size: 20, color: Colors.cyan.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipOption(CheckoutController checkout, double amount, String label) {
    final isSelected = !_isCustomTip && checkout.tipAmount == amount;
    return GestureDetector(
      onTap: () {
        setState(() => _isCustomTip = false);
        checkout.setTipAmount(amount);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.cyan : Colors.grey.shade100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipButton(CheckoutController checkout) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCustomTip = true;
          if (_customTipController.text.isEmpty) {
            _customTipController.text = '0.0';
            checkout.setTipAmount(0.0);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isCustomTip ? Colors.cyan : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _isCustomTip ? Colors.cyan : Colors.grey.shade100),
        ),
        child: Text(
          tr(context, 'checkout_custom'),
          style: TextStyle(
            color: _isCustomTip ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(tr(context, 'change')),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, 
    CheckoutController checkout, 
    String method, 
    IconData icon, 
    String subtitle, {
    bool isAvailable = true,
  }) {
    final isSelected = checkout.paymentMethod == method;
    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          checkout.selectPaymentMethod(method);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cash on delivery is not available for now'),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method, 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      )
                    ),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
              if (!isAvailable)
                Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, ProductModel product, int quantity, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.transparent, // Ensures taps register on whitespace
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.mainImage ?? product.thumbnail,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60, height: 60, color: Colors.grey[100],
                  child: const Icon(Icons.image_outlined, size: 20, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trText(context, product.name),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$quantity x AED ${product.finalPrice.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Text(
              'AED ${(product.finalPrice * quantity).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context, 
    CheckoutController checkout, 
    ProductModel? product, 
    int? quantity,
    ThemeData theme,
  ) {
    final checkout = context.read<CheckoutController>();
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final isVerified = auth.currentUser?.isPhoneVerified ?? false;
    
    final totalPrice = checkout.hasSummary 
        ? checkout.summaryTotal 
        : (product != null && quantity != null
            ? product.finalPrice * quantity
            : cart.totalPrice) + checkout.tipAmount;
    
    final bool canContinue = !checkout.isLoading && (checkout.currentStep != CheckoutStep.summary || isVerified);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AED ${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                ),
                Text(
                  tr(context, 'checkout_price_inclusive'),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: canContinue ? () => _handleAction(context, checkout, product, quantity) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: checkout.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      checkout.currentStep == CheckoutStep.payment 
                        ? tr(context, 'place_order') 
                        : tr(context, 'continue'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, CheckoutController checkout, ProductModel? product, int? quantity) async {
    if (checkout.currentStep == CheckoutStep.address) {
      if (checkout.selectedAddressId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an address'), backgroundColor: AppColors.error),
        );
        return;
      }
      if (checkout.deliveryDate == null || checkout.deliverySlotId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select preferred date and delivery slot'), backgroundColor: AppColors.error),
        );
        return;
      }
      checkout.nextStep();
    } else if (checkout.currentStep == CheckoutStep.summary) {
      checkout.nextStep();
    } else {
      final orderData = await checkout.placeOrder(product: product, quantity: quantity);
      if (orderData != null) {
        if (mounted) {
          // If payment was triggered, show integrated WebView
          if (orderData.containsKey('payment_url') && orderData['payment_url'] != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentWebViewScreen(
                  url: orderData['payment_url'],
                  title: tr(context, 'secure_payment'),
                  orderId: orderData['order_id'],
                ),
              ),
            );
            
            // PaymentWebViewScreen uses pop(result) which resolves the await above
            if (!mounted) return;

            // Route based on WebView response natively in OrderPage
            final orderIdStr = orderData['order_id'].toString();
            if (result == 'success') {
              checkout.reset();
              context.read<CartController>().clearCart();
              context.read<OrderController>().fetchMyOrders();
              Navigator.of(context).pushNamedAndRemoveUntil('/payment-success', (route) => route.isFirst, arguments: orderIdStr);
              return;
            } else if (result == 'failed') {
              Navigator.of(context).pushNamedAndRemoveUntil('/payment-failed', (route) => route.isFirst, arguments: orderIdStr);
              return;
            } else if (result == 'pending') {
              Navigator.of(context).pushNamedAndRemoveUntil('/order-pending', (route) => route.isFirst, arguments: orderIdStr);
              return;
            }
          }

          // After payment is complete (COD/Direct cases ONLY)
          checkout.startPaymentStatusPolling();
          
          // Refresh orders list
          context.read<OrderController>().fetchMyOrders();
          
          // Clear local state
          checkout.reset();
          context.read<CartController>().clearCart();
          
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(checkout.error ?? 'Failed to place order'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isTotal ? AppColors.primary : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(
    BuildContext context, 
    CheckoutController checkout, 
    CartController cart,
    ProductModel product, 
    int quantity, 
    bool isCartMode, 
    ThemeData theme
  ) {
    if (checkout.couponCode != null && couponController.text.isEmpty) {
      couponController.text = checkout.couponCode!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                tr(context, 'have_coupon'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponController,
                  decoration: InputDecoration(
                    hintText: tr(context, 'enter_coupon_code'),
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: checkout.isLoading 
                    ? null 
                    : () async {
                        final cartTotal = isCartMode ? cart.totalPrice : (product.finalPrice * quantity);
                        final success = await checkout.validateCoupon(
                          couponController.text.trim(),
                          cartTotal,
                        );
                        if (success) {
                           checkout.fetchCheckoutSummary(
                            product: isCartMode ? null : product,
                            quantity: isCartMode ? null : quantity,
                          );
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: checkout.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(tr(context, 'apply')),
                ),
              ),
            ],
          ),
          if (checkout.isCouponValid)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    tr(context, 'coupon_applied'),
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                    final cartTotal = isCartMode ? cart.totalPrice : (product.finalPrice * quantity);
                    checkout.validateCoupon(
                      '',
                      cartTotal,
                    );
                      checkout.fetchCheckoutSummary(
                        product: isCartMode ? null : product,
                        quantity: isCartMode ? null : quantity,
                      );
                    },
                    child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          if (checkout.error != null && !checkout.isCouponValid)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                checkout.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _buildAvailableCoupons(context, checkout, cart, product, quantity, isCartMode),
        ],
      ),
    );
  }

  Widget _buildAvailableCoupons(
    BuildContext context, 
    CheckoutController checkout,
    CartController cart,
    ProductModel product,
    int quantity,
    bool isCartMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'available_coupons').toUpperCase(),
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                checkout.availableCoupons.length.toString(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (checkout.isLoadingCoupons)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (checkout.availableCoupons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'No coupons available right now',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  TextButton(
                    onPressed: () => checkout.fetchAvailableCoupons(),
                    child: const Text('Tap to refresh', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          )
        else
          ...checkout.availableCoupons.map((coupon) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              coupon.code,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              coupon.discountAmount,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyan),
                            ),
                          ),
                        ],
                      ),
                      if (coupon.description != null && coupon.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            coupon.description!,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    couponController.text = coupon.code;
                    final cartTotal = isCartMode ? cart.totalPrice : (product.finalPrice * quantity);
                    final success = await checkout.validateCoupon(
                      coupon.code,
                      cartTotal,
                    );
                    if (success) {
                      checkout.fetchCheckoutSummary(
                        product: isCartMode ? null : product,
                        quantity: isCartMode ? null : quantity,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    tr(context, 'tap_to_apply'),
                    style: const TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTipInfo(BuildContext context, CheckoutController checkout) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.volunteer_activism, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr(context, 'tip_info'),
              style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationWarning(
    BuildContext context, 
    ProductModel displayProduct, 
    int displayQuantity, 
    bool isCartMode, 
    ThemeData theme
  ) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isVerified = user?.isPhoneVerified ?? false;

    if (isVerified) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.actionBlueLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.actionBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.actionBlue),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Phone Verification Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please verify your phone number to place an order. This helps us ensure reaching you for delivery.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (user != null) {
                  showDialog(
                    context: context,
                    builder: (context) => OtpVerificationDialog(
                      type: 'phone',
                      currentValue: user.phoneNumber ?? '',
                      userId: user.id,
                      onVerified: (identifier) async {
                        // Refresh auth state after verification
                        await auth.refreshProfile();
                        // Re-fetch cart to ensure it persists after token changes
                        if (context.mounted) {
                          context.read<CartController>().fetchCart();
                          
                          // Re-fetch summary now that the phone is verified!
                          final checkout = context.read<CheckoutController>();
                          checkout.fetchCheckoutSummary(
                            product: isCartMode ? null : displayProduct,
                            quantity: isCartMode ? null : displayQuantity,
                          );
                        }
                      },
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Verify Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
