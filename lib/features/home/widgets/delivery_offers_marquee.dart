import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/marketing/model/delivery_offer_model.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';

class DeliveryOffersMarquee extends StatefulWidget {
  final List<DeliveryOfferModel> offers;

  const DeliveryOffersMarquee({super.key, required this.offers});

  @override
  State<DeliveryOffersMarquee> createState() => _DeliveryOffersMarqueeState();
}

class _DeliveryOffersMarqueeState extends State<DeliveryOffersMarquee> {
  late final ScrollController _scrollController;
  Timer? _timer;
  final double _scrollSpeed = 0.5; // pixels per frame/tick

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Start scrolling after a short delay to ensure layout is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || !_scrollController.hasClients) return;

      // Moving to the LEFT (incrementing offset)
      double newOffset = _scrollController.offset + _scrollSpeed;

      // If we reach the end of the "first half", jump back to the start
      // to keep it infinite and seamless
      if (newOffset >= _scrollController.position.maxScrollExtent / 2) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();

    // Watch language changes to update localized text immediately
    final langProvider = context.watch<LanguageProvider>();
    final currentLocale = langProvider.locale;

    // Repeat items to ensure seamless loop
    final items = List.generate(10, (_) => widget.offers).expand((e) => e).toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.actionBlue.withOpacity(isDark ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.actionBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final offer = items[index];
            return _OfferItem(
              offer: offer, 
              locale: currentLocale,
            );
          },
        ),
      ),
    );
  }
}

class _OfferItem extends StatelessWidget {
  final DeliveryOfferModel offer;
  final String locale;

  const _OfferItem({
    required this.offer,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildText(
            context,
            offer.getFreeDelivery(locale),
            Icons.local_shipping_outlined,
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.actionBlue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          _buildText(
            context,
            offer.getDeliveryTime(locale),
            Icons.flash_on_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(width: 40), // Gap between repeating items
        ],
      ),
    );
  }

  Widget _buildText(BuildContext context, String text, IconData icon, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? AppColors.actionBlue,
        ),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
