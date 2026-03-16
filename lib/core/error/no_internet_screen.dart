import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';

class PremiumNoInternetScreen extends StatefulWidget {
  const PremiumNoInternetScreen({super.key});

  @override
  State<PremiumNoInternetScreen> createState() => _PremiumNoInternetScreenState();
}

class _PremiumNoInternetScreenState extends State<PremiumNoInternetScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─── Animated Premium Fish ────────────────────────
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 15 * _scaleAnimation.value * (1.0 - _opacityAnimation.value)), // Complex bobbing
                    child: child,
                  );
                },
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.02),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/no_internet_fish.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // ─── "OOPS!" Header ─────────────────────────────
              const Text(
                'OOPS!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // ─── Title ──────────────────────────────────────
              Text(
                tr(context, 'no_internet_title').toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              // ─── Message ────────────────────────────────────
              Text(
                tr(context, 'no_internet_message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // ─── Try Again Button ───────────────────────────
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    // This is handled automatically by the provider, 
                    // but we can add a haptic or manual refresh here if needed.
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    tr(context, 'retry_btn'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
