import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';

class GrillFryBanner extends StatelessWidget {
  const GrillFryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/grill_and_fry.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF202822).withValues(alpha: .95),
                    const Color(0xFF202822).withValues(alpha: .40),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.outdoor_grill_rounded,
                  color: Color(0xFFD6BE91),
                  size: 28,
                ),
                const SizedBox(height: 18),
                Text(
                  tr(context, 'cat_grill_and_fry'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(context, 'grill_fry_subtitle'),
                  style: const TextStyle(
                    color: Color(0xFFE4E5DF),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  tr(context, 'grill_fry_customise'),
                  style: const TextStyle(
                    color: Color(0xFFD6BE91),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
