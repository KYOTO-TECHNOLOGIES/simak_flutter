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

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();

    final langProvider = context.watch<LanguageProvider>();
    final currentLocale = langProvider.locale;

    final List<_OfferData> allOffers = [];
    for (var offer in offers) {
      final freeText = offer.getFreeDelivery(currentLocale);
      if (freeText.isNotEmpty) {
        allOffers.add(
          _OfferData(
            title: freeText,
            subtitle: tr(context, 'limited time offer'),
            icon: Icons.local_shipping_rounded,
            gradient: [
              const Color.fromARGB(255, 1, 109, 136),
              const Color.fromARGB(255, 2, 98, 123),
            ], // Deep Brand Teal
            accentColor: AppColors.accent,
          ),
        );
      }
      final timeText = offer.getDeliveryTime(currentLocale);
      if (timeText.isNotEmpty) {
        allOffers.add(
          _OfferData(
            title: timeText,
            subtitle: tr(context, 'express delivery'),
            icon: Icons.flash_on_rounded,
            gradient: [
              const Color(0xFF1297BA),
              const Color(0xFF0D7A96),
            ], // Action Blue
            accentColor: Colors.white,
          ),
        );
      }
    }

    if (allOffers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const SizedBox(height: 16),
          ...allOffers.map((offer) => _OfferCard(offer: offer)).toList(),
        ],
      ),
    );
  }
}

class _OfferData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;

  _OfferData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });
}

class _OfferCard extends StatelessWidget {
  final _OfferData offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: offer.gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: offer.gradient.first.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                offer.icon,
                size: 80,
                color: Colors.white.withOpacity(0.06),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(offer.icon, color: offer.accentColor, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.subtitle,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white54,
                      size: 14,
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
