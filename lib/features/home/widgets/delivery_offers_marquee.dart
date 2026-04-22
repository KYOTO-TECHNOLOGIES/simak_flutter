import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/marketing/model/delivery_offer_model.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';

class _OfferPart {
  final String text;
  final IconData icon;
  final Color? color;

  _OfferPart({required this.text, required this.icon, this.color});
}

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

      double newOffset = _scrollController.offset + _scrollSpeed;

      // Infinite loop logic
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

    final langProvider = context.watch<LanguageProvider>();
    final currentLocale = langProvider.locale;

    // Flatten all offers into individual parts (Free Delivery, Time, etc.)
    final List<_OfferPart> allParts = [];
    for (var offer in widget.offers) {
      final freeText = offer.getFreeDelivery(currentLocale);
      if (freeText.isNotEmpty) {
        allParts.add(
          _OfferPart(text: freeText, icon: Icons.local_shipping_outlined),
        );
      }
      final timeText = offer.getDeliveryTime(currentLocale);
      if (timeText.isNotEmpty) {
        allParts.add(
          _OfferPart(
            text: timeText,
            icon: Icons.flash_on_rounded,
            color: AppColors.accent,
          ),
        );
      }
    }

    if (allParts.isEmpty) return const SizedBox.shrink();

    // Repeat parts to ensure seamless loop
    final items = List.generate(10, (_) => allParts).expand((e) => e).toList();

    return Container(
      height: 45, // Slightly taller for cards
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final part = items[index];
          return _OfferCard(part: part);
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _OfferPart part;

  const _OfferCard({required this.part});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 12), // Space between cards
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.actionBlue.withOpacity(isDark ? 0.12 : 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.actionBlue.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(part.icon, size: 16, color: part.color ?? AppColors.actionBlue),
          const SizedBox(width: 8),
          Text(
            part.text.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
