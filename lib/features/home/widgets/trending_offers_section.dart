import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/marketing/model/delivery_offer_model.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class TrendingOffersSection extends StatelessWidget {
  final List<DeliveryOfferModel> offers;

  const TrendingOffersSection({super.key, required this.offers});

  List<_OfferData> _prepareOffers(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final currentLocale = langProvider.locale;
    final List<_OfferData> allOffers = [];

    for (var offer in offers) {
      final freeText = offer.getFreeDelivery(currentLocale);
      if (freeText.isNotEmpty) {
        allOffers.add(
          _OfferData(
            id: 'free_${offer.id}',
            title: freeText,
            subtitle: tr(context, 'limited_time_offer'),
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFF006D85),
            iconColor: Colors.orange.shade400,
          ),
        );
      }
      final timeText = offer.getDeliveryTime(currentLocale);
      if (timeText.isNotEmpty) {
        allOffers.add(
          _OfferData(
            id: 'time_${offer.id}',
            title: timeText,
            subtitle: tr(context, 'express_delivery'),
            icon: Icons.flash_on_rounded,
            color: const Color(0xFF0090B0),
            iconColor: Colors.white,
          ),
        );
      }
    }
    return allOffers;
  }

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();

    final allOffers = _prepareOffers(context);
    if (allOffers.isEmpty) return const SizedBox.shrink();

    final displayOffers = allOffers.take(2).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          _OfferCard(offer: displayOffers[0]),
          if (displayOffers.length > 1) ...[
            const SizedBox(height: 4), // Reduced from 8 to 4
            _OfferCard(offer: displayOffers[1]),
          ],
        ],
      ),
    );
  }
}

class _OfferData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;

  _OfferData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
  });
}

class _OfferCard extends StatelessWidget {
  final _OfferData offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: offer.color,
        borderRadius: BorderRadius.circular(14), // Slightly tighter radius for professional look
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned(
              right: -5,
              bottom: -5,
              child: Icon(
                offer.icon,
                size: 50,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Smaller Left Icon
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(offer.icon, color: offer.iconColor, size: 15),
                  ),
                  const SizedBox(width: 14),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          offer.title.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                       
                      ],
                    ),
                  ),
             
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
