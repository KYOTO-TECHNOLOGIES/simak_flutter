import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';

// ─── Social icon types ────────────────────────────────────────────
enum _IconType { whatsapp, instagram, facebook, twitter, tiktok, snapchat }

// ─── Data model ───────────────────────────────────────────────────
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

  // Ordered top → bottom (WhatsApp nearest FAB at index 5)
  static const List<_SocialData> _items = [
    _SocialData(
      label: 'Instagram',
      color: Color(0xFFE1306C),
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

    _SocialData(
      label: 'TikTok',
      color: Color(0xFF010101),
      shadowColor: Color(0xFF69C9D0),
      url: 'https://tiktok.com',
      iconType: _IconType.tiktok,
    ),
    _SocialData(
      label: 'Snapchat',
      color: Color(0xFFFFFC00),
      shadowColor: Color(0xFFFFFC00),
      url: 'https://snapchat.com',
      iconType: _IconType.snapchat,
    ),
    _SocialData(
      label: 'WhatsApp',
      color: Color(0xFF25D366),
      shadowColor: Color(0xFF25D366),
      // wa.me link — digits only, no +
      url: 'https://wa.me/971545446111',
      iconType: _IconType.whatsapp,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    // For WhatsApp, try native URI first then fall back to wa.me
    if (url.startsWith('https://wa.me/')) {
      final number = url.replaceFirst('https://wa.me/', '');
      final nativeUri = Uri.parse('whatsapp://send?phone=$number');
      final webUri = Uri.parse(url);
      try {
        if (await canLaunchUrl(nativeUri)) {
          await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Staggered animation: bottom item (WhatsApp, index 5) opens first,
  /// top item (Instagram, index 0) opens last.
  Animation<double> _itemAnimation(int index) {
    final reversedIndex = _items.length - 1 - index;
    final start = reversedIndex * 0.09;
    final end = (start + 0.58).clamp(0.0, 1.0);
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
        for (int i = 0; i < _items.length; i++) ...[
          _SocialButton(
            data: _items[i],
            animation: _itemAnimation(i),
            onTap: () => _launch(_items[i].url),
          ),
          const SizedBox(height: 8),
        ],
        _MainFab(isOpen: _isOpen, onTap: _toggle, controller: _controller),
      ],
    );
  }
}

// ─── Social button row ────────────────────────────────────────────
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

  Widget _buildIcon(_IconType type, Color bg) {
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
      case _IconType.tiktok:
        return CustomPaint(size: const Size(22, 22), painter: _TikTokPainter());
      case _IconType.snapchat:
        // Snapchat has yellow bg — use dark icon
        return CustomPaint(size: const Size(22, 22), painter: _SnapchatPainter());
      case _IconType.whatsapp:
        return CustomPaint(size: const Size(24, 24), painter: _WhatsAppPainter());
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.data.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.data.shadowColor.withOpacity(0.42),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildIcon(widget.data.iconType, widget.data.color),
                ),
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

// ══════════════════════════════════════════════════════════════════
//  C U S T O M   P A I N T E R S
// ══════════════════════════════════════════════════════════════════

// ─── Instagram ────────────────────────────────────────────────────
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.width * 0.28),
      ),
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.27,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.24),
      size.width * 0.075,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── X / Twitter ──────────────────────────────────────────────────
class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── WhatsApp ─────────────────────────────────────────────────────
class _WhatsAppPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Speech bubble body (rounded rect)
    final bubblePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h * 0.82),
          Radius.circular(w * 0.22),
        ),
      );
    // Tail at bottom-left
    bubblePath
      ..moveTo(w * 0.15, h * 0.82)
      ..lineTo(w * 0.05, h)
      ..lineTo(w * 0.35, h * 0.82)
      ..close();
    canvas.drawPath(bubblePath, fill);

    // Phone handset inside (dark green)
    final phonePaint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Simplified phone arc
    final phonePath = Path();
    phonePath.moveTo(w * 0.30, h * 0.22);
    phonePath.cubicTo(
      w * 0.28, h * 0.36,
      w * 0.25, h * 0.44,
      w * 0.32, h * 0.52,
    );
    phonePath.cubicTo(
      w * 0.40, h * 0.60,
      w * 0.48, h * 0.57,
      w * 0.62, h * 0.55,
    );
    canvas.drawPath(phonePath, phonePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── TikTok ───────────────────────────────────────────────────────
class _TikTokPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // TikTok logo: a stylised musical note / "d" shape
    // We draw it in white (since bg is black)
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cyanPaint = Paint()
      ..color = const Color(0xFF69C9D0)
      ..style = PaintingStyle.fill;

    // Cyan shadow copy (offset slightly top-right)
    _drawTikTokShape(canvas, w, h, cyanPaint, dx: -w * 0.06, dy: w * 0.06);
    // White foreground
    _drawTikTokShape(canvas, w, h, whitePaint, dx: 0, dy: 0);
  }

  void _drawTikTokShape(
    Canvas canvas,
    double w,
    double h,
    Paint paint, {
    double dx = 0,
    double dy = 0,
  }) {
    // Vertical bar (stem)
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34 + dx, h * 0.06 + dy, w * 0.18, h * 0.70),
      Radius.circular(w * 0.09),
    );
    canvas.drawRRect(stemRect, paint);

    // Note head (circle at bottom-left of stem)
    canvas.drawCircle(
      Offset(w * 0.30 + dx, h * 0.76 + dy),
      w * 0.18,
      paint,
    );

    // Curved flag at top-right of stem
    final flagPath = Path()
      ..moveTo(w * 0.52 + dx, h * 0.06 + dy)
      ..cubicTo(
        w * 0.74 + dx, h * 0.04 + dy,
        w * 0.82 + dx, h * 0.20 + dy,
        w * 0.80 + dx, h * 0.38 + dy,
      )
      ..lineTo(w * 0.62 + dx, h * 0.36 + dy)
      ..cubicTo(
        w * 0.65 + dx, h * 0.24 + dy,
        w * 0.62 + dx, h * 0.16 + dy,
        w * 0.52 + dx, h * 0.18 + dy,
      )
      ..close();
    canvas.drawPath(flagPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Snapchat ─────────────────────────────────────────────────────
class _SnapchatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Snapchat ghost — drawn in dark (since bg is bright yellow)
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Ghost body: oval head
    path.addOval(Rect.fromLTWH(w * 0.15, h * 0.02, w * 0.70, h * 0.60));

    // Body trapezoid
    path.moveTo(w * 0.15, h * 0.42);
    path.lineTo(w * 0.10, h * 0.82);
    // Bottom left wave
    path.quadraticBezierTo(w * 0.15, h * 0.95, w * 0.25, h * 0.85);
    path.quadraticBezierTo(w * 0.35, h * 0.75, w * 0.50, h * 0.88);
    // Bottom right wave (mirror)
    path.quadraticBezierTo(w * 0.65, h * 0.75, w * 0.75, h * 0.85);
    path.quadraticBezierTo(w * 0.85, h * 0.95, w * 0.90, h * 0.82);
    path.lineTo(w * 0.85, h * 0.42);
    path.close();

    canvas.drawPath(path, paint);

    // Eyes: two white circles
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.37, h * 0.34), w * 0.07, eyePaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.34), w * 0.07, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
