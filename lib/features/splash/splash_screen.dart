import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _swimController;
  late AnimationController _waveController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _swimAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Icon scale-in
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Text/tagline fade
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Fish swim (gentle bob)
    _swimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _swimAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _swimController, curve: Curves.easeInOut),
    );

    // Wave dots
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

    // Sequence the animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _fadeController.forward();
    });

    // Navigate after splash (controlled by animation completion or fallback)
    // We'll keep a fallback timer just in case, but primary navigation is via callback
    _fallbackTimer();
  }

  void _fallbackTimer() {
    Future.delayed(const Duration(milliseconds: 10000), () {
      if (mounted) _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;
    final langProvider = context.read<LanguageProvider>();

    // Wait if not initialized yet
    while (!langProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (mounted) {
      final auth = context.read<AuthController>();
      if (auth.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/language_selection');
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _swimController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              AppColors.lightGrey.withOpacity(0.5),
              AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── Animated Fish Icon ──────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_scaleAnimation, _swimAnimation]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _swimAnimation.value),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                    child: const Center(
                      child: Image(
                        image: AssetImage('assets/images/home_logo.png'),
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                ),

                const SizedBox(height: 36),

                // ─── App Name (Animated 3-Language Sequence) ─────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _LanguageAnimator(
                    onComplete: _navigateToNext,
                  ),
                ),

                const SizedBox(height: 70),

                // ─── Wave Dots Loader ─────────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _WaveDots(waveAnimation: _waveAnimation),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sequential Language Animator ──────────────────────────────────
class _LanguageAnimator extends StatefulWidget {
  final VoidCallback onComplete;

  const _LanguageAnimator({required this.onComplete});

  @override
  State<_LanguageAnimator> createState() => _LanguageAnimatorState();
}

class _LanguageAnimatorState extends State<_LanguageAnimator> {
  int _currentIndex = 0;
  final List<String> _locales = ['en', 'cn', 'ar'];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    // Wait for the initial icons/elements to fade in before starting sequence
    await Future.delayed(const Duration(milliseconds: 800));
    
    for (int i = 0; i < _locales.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() {
        _currentIndex = i + 1;
      });
    }

    // After showing the last language (Arabic) for 1.2 seconds, trigger navigation
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Text(
        _getLocalizedName(_locales[_currentIndex]),
        key: ValueKey<int>(_currentIndex),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedName(String locale) {
    if (locale == 'en') return 'Simak Fresh';
    if (locale == 'cn') return '西马克生鲜';
    if (locale == 'ar') return 'سيماك فريش';
    return 'Simak Fresh';
  }
}

// ─── Wave Dots ───────────────────────────────────────────────────────
class _WaveDots extends StatelessWidget {
  final Animation<double> waveAnimation;

  const _WaveDots({required this.waveAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveAnimation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.3;
            final value = (waveAnimation.value + delay) % 1.0;
            final yOffset = -6.0 * (1 - (value - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, yOffset),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.4 + 0.5 * value),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
