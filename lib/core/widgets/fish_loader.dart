import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';

/// A seafood-themed loading indicator that replaces the generic spinner.
/// Shows a swimming fish icon with animated wave dots below.
class FishLoader extends StatefulWidget {
  final String? message;

  const FishLoader({super.key, this.message});

  @override
  State<FishLoader> createState() => _FishLoaderState();
}

class _FishLoaderState extends State<FishLoader>
    with TickerProviderStateMixin {
  late AnimationController _swimController;
  late AnimationController _waveController;
  late AnimationController _fadeController;

  late Animation<double> _swimY;
  late Animation<double> _swimX;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Bob up/down
    _swimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _swimY = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _swimController, curve: Curves.easeInOut),
    );

    // Slight horizontal sway
    _swimX = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _swimController, curve: Curves.easeInOut),
    );

    // Wave dots
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _swimController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Swimming Fish ───────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_swimY, _swimX]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_swimX.value, _swimY.value),
                  child: child,
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '🦞',
                    style: TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Wave Dots ───────────────────────────────────────
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(3, (i) {
                    final phase = (_waveController.value - i * 0.25) % 1.0;
                    final height = 6.0 + 6.0 * (0.5 - (phase - 0.5).abs()) * 2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 7,
                        height: height.clamp(4.0, 12.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.5 + 0.5 * (height / 12.0)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            // ─── Optional Message ────────────────────────────────
            if (widget.message != null) ...[
              const SizedBox(height: 14),
              Text(
                widget.message!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
