import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';

// ─── Social icon type ────────────────────────────────────────────
enum _IconType { instagram, facebook, twitter }

// ─── Data model ──────────────────────────────────────────────────
class _SocialData {
  final String label;
  final Color color;
  final Color shadowColor;
  final String url;
  final _IconType iconType;

  const _SocialData({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.url,
    required this.iconType,
  });
}

// ─── Main exported widget ─────────────────────────────────────────
class FloatingContactButton extends StatefulWidget {
  const FloatingContactButton({super.key});

  @override
  State<FloatingContactButton> createState() => _FloatingContactButtonState();
}

class _FloatingContactButtonState extends State<FloatingContactButton>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;

  // Ordered top → bottom (Instagram at top, X nearest FAB)
  static const List<_SocialData> _items = [
    _SocialData(
      label: 'Instagram',
      color: Color.fromARGB(255, 161, 29, 58),
      shadowColor: Color(0xFFE1306C),
      url: 'https://instagram.com',
      iconType: _IconType.instagram,
    ),
    _SocialData(
      label: 'Facebook',
      color: Color(0xFF1877F2),
      shadowColor: Color(0xFF1877F2),
      url: 'https://facebook.com',
      iconType: _IconType.facebook,
    ),

  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _controller.reverse().then((_) {
        if (mounted) setState(() => _isOpen = false);
      });
    } else {
      setState(() => _isOpen = true);
      _controller.forward();
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Each item animates with a stagger.
  /// Bottom item (X, index 2) opens first; top item (Instagram, index 0) opens last.
  Animation<double> _itemAnimation(int index) {
    final reversedIndex = _items.length - 1 - index;
    final start = reversedIndex * 0.13;
    final end = (start + 0.62).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Social buttons
        for (int i = 0; i < _items.length; i++) ...[
          _SocialButton(
            data: _items[i],
            animation: _itemAnimation(i),
            onTap: () => _launch(_items[i].url),
          ),
          const SizedBox(height: 10),
        ],
        // Main FAB
        _MainFab(isOpen: _isOpen, onTap: _toggle, controller: _controller),
      ],
    );
  }
}

// ─── Social button row (label + circle icon) ──────────────────────
class _SocialButton extends StatefulWidget {
  final _SocialData data;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _SocialButton({
    required this.data,
    required this.animation,
    required this.onTap,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  Widget _buildIcon(_IconType type) {
    switch (type) {
      case _IconType.instagram:
        return CustomPaint(size: const Size(22, 22), painter: _InstagramPainter());
      case _IconType.facebook:
        return const Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        );
      case _IconType.twitter:
        return CustomPaint(size: const Size(20, 20), painter: _XPainter());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final v = widget.animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.scale(
            scale: v,
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.data.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Circle icon
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.data.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.data.shadowColor.withOpacity(0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(child: _buildIcon(widget.data.iconType)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main FAB button ──────────────────────────────────────────────
class _MainFab extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;
  final AnimationController controller;

  const _MainFab({
    required this.isOpen,
    required this.onTap,
    required this.controller,
  });

  @override
  State<_MainFab> createState() => _MainFabState();
}

class _MainFabState extends State<_MainFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.actionBlue, AppColors.primary],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.actionBlue.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              widget.isOpen ? Icons.close_rounded : Icons.headset_mic_rounded,
              key: ValueKey(widget.isOpen),
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Instagram custom painter ─────────────────────────────────────
class _InstagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Outer rounded rect
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.28),
    );
    canvas.drawRRect(rrect, stroke);

    // Inner circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.27,
      stroke,
    );

    // Corner dot
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.24),
      size.width * 0.075,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── X / Twitter custom painter ──────────────────────────────────
class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left to bottom-right diagonal
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    // Top-right to bottom-left diagonal
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Pulse animation wrapper (optional decorative ring) ──────────
class _PulseRing extends StatefulWidget {
  final Widget child;
  const _PulseRing({required this.child});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scale = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.actionBlue.withOpacity(_opacity.value),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
