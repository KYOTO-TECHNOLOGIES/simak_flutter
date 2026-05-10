import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/marketing/model/delivery_offer_model.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class TrendingOffersSection extends StatefulWidget {
  final List<DeliveryOfferModel> offers;

  const TrendingOffersSection({super.key, required this.offers});

  @override
  State<TrendingOffersSection> createState() => _TrendingOffersSectionState();
}

class _TrendingOffersSectionState extends State<TrendingOffersSection> {
  int _currentIndex = 0;
  Timer? _timer;
  final List<_OfferData> _allOffers = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_allOffers.isNotEmpty && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _allOffers.length;
        });
      }
    });
  }

  void _prepareOffers(String currentLocale) {
    _allOffers.clear();
    for (var offer in widget.offers) {
      final freeText = offer.getFreeDelivery(currentLocale);
      if (freeText.isNotEmpty) {
        _allOffers.add(
          _OfferData(
            id: 'free_${offer.id}',
            title: freeText,
            icon: Icons.local_shipping_rounded,
            gradient: [
              const Color.fromARGB(255, 1, 77, 96), // primaryDark
              const Color.fromARGB(255, 38, 158, 188), // primary
            ],
            accentColor: AppColors.accent,
          ),
        );
      }
      final timeText = offer.getDeliveryTime(currentLocale);
      if (timeText.isNotEmpty) {
        _allOffers.add(
          _OfferData(
            id: 'time_${offer.id}',
            title: timeText,
            icon: Icons.flash_on_rounded,
            gradient: [
              const Color.fromARGB(255, 9, 102, 126), // Darker action blue
              const Color(0xFF1297BA), // actionBlue
            ],
            accentColor: const Color(0xFFE1F5FE), // actionBlueLight
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();

    final langProvider = context.watch<LanguageProvider>();
    final currentLocale = langProvider.locale;

    _prepareOffers(currentLocale);

    if (_allOffers.isEmpty) return const SizedBox.shrink();

    // Ensure _currentIndex is within bounds if offers changed
    if (_currentIndex >= _allOffers.length) {
      _currentIndex = 0;
    }

    final currentOffer = _allOffers[_currentIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _OfferCard(
          key: ValueKey(currentOffer.id),
          offer: currentOffer,
        ),
      ),
    );
  }
}

class _OfferData {
  final String id;
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;

  _OfferData({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });
}

class _OfferCard extends StatelessWidget {
  final _OfferData offer;

  const _OfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: offer.gradient,
        ),
        borderRadius: BorderRadius.circular(20), // More rounded for modern look
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: offer.gradient.first.withOpacity(0.2),
            blurRadius: 17,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
            Container(
              height: 53, // Slightly taller for better breathing room
              padding: const EdgeInsets.symmetric(horizontal: 16), // More horizontal padding
              child: Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(offer.icon, color: offer.accentColor, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      offer.title.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9, // Optimized size for premium feel
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        height: 1.2,
                      ),
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
