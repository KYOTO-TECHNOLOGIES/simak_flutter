import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          // Subtle "HOW IT WORKS" Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8FB),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE1EFF5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.waves, size: 12, color: Color(0xFF00ACC1)),
                const SizedBox(width: 8),
                Text(
                  tr(context, 'how_it_works'),
                  style: const TextStyle(
                    color: Color(0xFF546E7A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Dual-Tone Headline
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: theme.textTheme.displayLarge?.fontFamily,
                height: 1.1,
              ),
              children: [
                TextSpan(
                  text: tr(context, 'from_ocean_to'),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                TextSpan(
                  text: tr(context, 'your_plate'),
                  style: const TextStyle(color: Color(0xFF00ACC1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              tr(context, 'how_it_works_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 60),
          
          // Grid-like layout for mobile (2 columns for better horizontal flow)
          Wrap(
            spacing: 20,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _buildStepCard(
                context,
                number: '01',
                title: tr(context, 'step_1_title'),
                desc: tr(context, 'step_1_desc'),
                tags: tr(context, 'step_1_tags'),
                icon: Icons.search_rounded,
                color: const Color(0xFF00ACC1),
              ),
              _buildStepCard(
                context,
                number: '02',
                title: tr(context, 'step_2_title'),
                desc: tr(context, 'step_2_desc'),
                tags: tr(context, 'step_2_tags'),
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFFFBC02D),
              ),
              _buildStepCard(
                context,
                number: '03',
                title: tr(context, 'step_3_title'),
                desc: tr(context, 'step_3_desc'),
                tags: tr(context, 'step_3_tags'),
                icon: Icons.local_shipping_rounded,
                color: const Color(0xFF0288D1),
              ),
              _buildStepCard(
                context,
                number: '04',
                title: tr(context, 'step_4_title'),
                desc: tr(context, 'step_4_desc'),
                tags: tr(context, 'step_4_tags'),
                icon: Icons.restaurant_rounded,
                color: const Color(0xFFF9A825),
              ),
            ],
          ),
          
          const SizedBox(height: 60),
          
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00ACC1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00ACC1).withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(context, 'start_shopping'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'free_delivery_threshold'),
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.35),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String number,
    required String title,
    required String desc,
    required String tags,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    // We target a grid on mobile to look less like a vertical list
    final cardWidth = (size.width - 60) / 2;
    
    return SizedBox(
      width: cardWidth.clamp(140.0, 180.0),
      child: Column(
        children: [
          // Icon Box with Number Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 38),
              ),
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    number,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Text Content
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          
          // Tags
          Text(
            tags,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
