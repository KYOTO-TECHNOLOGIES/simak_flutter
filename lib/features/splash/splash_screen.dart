import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainFadeController;
  late AnimationController _logoFloatController;
  late AnimationController _introController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    _mainFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.75, end: 1.05).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
        weight: 40,
      ),
    ]).animate(_introController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOut,
      ),
    );

    _introController.forward().then((_) {
      if (mounted) {
        _mainFadeController.forward();
      }
    });

    _logoFloatController.repeat(reverse: true);

    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    final langProvider = context.read<LanguageProvider>();
    while (!langProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
  }

  void _onAnimationComplete() {
    if (mounted) {
      setState(() => _isVisible = false);
      _navigateToNext();
    }
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final auth = context.read<AuthController>();

    if (auth.isLoggedIn) {
      if (auth.isDeliveryUser) {
        Navigator.of(context).pushReplacementNamed('/delivery_dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      final langProvider = context.read<LanguageProvider>();
      if (langProvider.hasSelectedLanguage) {
        Navigator.of(context).pushReplacementNamed('/home', arguments: 2);
      } else {
        Navigator.of(context).pushReplacementNamed('/language_selection');
      }
    }
  }

  @override
  void dispose() {
    _mainFadeController.dispose();
    _logoFloatController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2E40),
      body: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _logoFloatController,
              _introController,
            ]),
            builder: (context, child) {
              final floatOffset = -6 *
                  math.sin(
                    _logoFloatController.value * 2 * math.pi,
                  );
              return Opacity(
                opacity: _logoOpacity.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: const Image(
                          image: AssetImage('assets/images/home_logo.png'),
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _LanguageAnimator(onComplete: _onAnimationComplete),

                    const SizedBox(height: 20),

                    const _WaveDivider(),

                    const SizedBox(height: 12),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _BouncingCreature(
                          image: 'assets/images/fish1.png',
                          color: Color(0xFF04BCB1),
                          delayMs: 0,
                        ),
                        SizedBox(width: 28),
                        _BouncingCreature(
                          image: 'assets/images/fish2.png',
                          color: Color(0xFFF6DE37),
                          delayMs: 175,
                        ),
                        SizedBox(width: 28),
                        _BouncingCreature(
                          image: 'assets/images/fish3.png',
                          color: Color(0xFFFF4D4D),
                          delayMs: 0,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LanguageAnimator extends StatefulWidget {
  final VoidCallback onComplete;

  const _LanguageAnimator({required this.onComplete});

  @override
  State<_LanguageAnimator> createState() => _LanguageAnimatorState();
}

class _LanguageAnimatorState extends State<_LanguageAnimator> {
  int _currentIndex = 0;
  final List<Map<String, String>> _languages = [
    {'a': 'SIMAK', 'b': 'FRESH'},
    {'a': 'سيماك', 'b': 'فريش'},
    {'a': '西马克', 'b': '生鲜'},
  ];

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _currentIndex = 1);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _currentIndex = 2);
    await Future.delayed(const Duration(milliseconds: 600));

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _languages[_currentIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final inAnimation =
            Tween<Offset>(
              begin: const Offset(0.3, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: inAnimation, child: child),
        );
      },
      child: _ShimmerText(
        key: ValueKey<int>(_currentIndex),
        textA: lang['a']!,
        textB: lang['b']!,
      ),
    );
  }
}

class _ShimmerText extends StatefulWidget {
  final String textA;
  final String textB;

  const _ShimmerText({super.key, required this.textA, required this.textB});

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFF6DE37),
                Color(0xFFFEF08A),
                Color(0xFFFFFFFF),
                Color(0xFFFEF08A),
                Color(0xFFF6DE37),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _shimmerController.value,
              ),
            ).createShader(bounds);
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                  fontFamily: 'sans-serif',
                ),
                children: [
                  TextSpan(text: widget.textA.toUpperCase()),
                  const TextSpan(text: ' '),
                  TextSpan(text: widget.textB.toUpperCase()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}

class _BouncingCreature extends StatefulWidget {
  final String image;
  final Color color;
  final int delayMs;

  const _BouncingCreature({
    required this.image,
    required this.color,
    required this.delayMs,
  });

  @override
  State<_BouncingCreature> createState() => _BouncingCreatureState();
}

class _BouncingCreatureState extends State<_BouncingCreature>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _yAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _yAnimation = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _bounceController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _yAnimation.value),
              child: child,
            );
          },
          child: Image.asset(
            widget.image,
            height: 38,
            width: 38,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.waves, color: widget.color, size: 20),
              );
            },
          ),
        ),
        const SizedBox(height: 3),
        AnimatedBuilder(
          animation: _bounceController,
          builder: (context, __) {
            final double scale = (1.0 + _yAnimation.value / 60.0).clamp(
              0.5,
              1.0,
            );
            return Container(
              width: 40 * scale,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: RadialGradient(
                  colors: [widget.color.withOpacity(0.25), Colors.transparent],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WaveDivider extends StatelessWidget {
  const _WaveDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 7,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF04BCB1).withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);

    path.quadraticBezierTo(
      size.width * 0.125,
      0,
      size.width * 0.25,
      size.height / 2,
    );
    path.quadraticBezierTo(
      size.width * 0.375,
      size.height,
      size.width * 0.5,
      size.height / 2,
    );
    path.quadraticBezierTo(
      size.width * 0.625,
      0,
      size.width * 0.75,
      size.height / 2,
    );
    path.quadraticBezierTo(
      size.width * 0.875,
      size.height,
      size.width,
      size.height / 2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
