import 'package:flutter/material.dart';

import '../models/card_model.dart';

/// Diamond (non-foil) or stretched-hexagon (foil) rarity badge.
class RarityBadge extends StatelessWidget {
  final CardModel card;

  const RarityBadge({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final label = card.isFoil ? 'Rarity: ${card.rarity}, Foil' : 'Rarity: ${card.rarity}';
    if (card.isFoil) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: _FoilHexBadge(text: '${card.rarity} · Foil'),
      );
    }
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: _DiamondBadge(text: card.rarity),
    );
  }
}

// ── Diamond badge (non-foil: C, U) ─────────────────────────────────────────

class _DiamondBadge extends StatelessWidget {
  static const double _size = 28;

  final String text;
  const _DiamondBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSingle = text.length == 1;

    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _DiamondPainter(isDark: isDark),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFFF0EEF8),
              fontSize: isSingle ? 11.0 : 9.0,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  final bool isDark;
  const _DiamondPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.5)
      ..close();

    // Fill
    final fillPaint = Paint();
    if (isDark) {
      fillPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC0B8D0), Color(0xFFA098B8), Color(0xFF807898)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      fillPaint.color = const Color(0xFF7B6BAE);
    }
    canvas.drawPath(path, fillPaint);

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF585068)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Subtle inner highlight along the top-left and top-right edges.
    final highlightPath = Path()
      ..moveTo(w * 0.15, h * 0.35)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.85, h * 0.35);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DiamondPainter old) => old.isDark != isDark;
}

// ── Foil hexagon badge ──────────────────────────────────────────────────────

class _FoilHexBadge extends StatelessWidget {
  final String text;
  const _FoilHexBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _HexClipper(),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        constraints: const BoxConstraints(minWidth: 44),
        // Rainbow gradient at ~135°
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [
              Color(0xFFF8C8C8),
              Color(0xFFF8E898),
              Color(0xFFC8F0C8),
              Color(0xFFC0E0F8),
              Color(0xFFD8C8F8),
              Color(0xFFF8C8E8),
            ],
          ),
        ),
        // Sheen painted as a foreground over the rainbow
        foregroundDecoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x40FFFFFF), // 25% white — 3D highlight at top
              Color(0x00FFFFFF), // transparent at midpoint
              Color(0x14000000), // 8% black shadow at bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1A1020),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            // Engraved look: light above, shadow below.
            shadows: [
              Shadow(
                color: Color(0x50FFFFFF),
                offset: Offset(0, -0.5),
                blurRadius: 1,
              ),
              Shadow(
                color: Color(0x30000000),
                offset: Offset(0, 0.5),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clip path matching CSS polygon(10% 0%, 90% 0%, 100% 50%, 90% 100%, 10% 100%, 0% 50%).
class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.10, 0)
      ..lineTo(w * 0.90, 0)
      ..lineTo(w, h * 0.50)
      ..lineTo(w * 0.90, h)
      ..lineTo(w * 0.10, h)
      ..lineTo(0, h * 0.50)
      ..close();
  }

  @override
  bool shouldReclip(_HexClipper old) => false;
}

// ── Diamond painter reused by DupeDot ──────────────────────────────────────

/// Utility: paints a diamond (vertices at the four edge midpoints of [rect])
/// using the muted purple-silver gradient (dark) or solid #7B6BAE (light).
/// Exported so DupeDot can share the same visual language without duplicating
/// gradient constants.
void paintMutedDiamond(Canvas canvas, Size size, {required bool isDark}) {
  final w = size.width;
  final h = size.height;
  final path = Path()
    ..moveTo(w * 0.5, 0)
    ..lineTo(w, h * 0.5)
    ..lineTo(w * 0.5, h)
    ..lineTo(0, h * 0.5)
    ..close();

  final paint = Paint();
  if (isDark) {
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC0B8D0), Color(0xFFA098B8), Color(0xFF807898)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
  } else {
    paint.color = const Color(0xFF7B6BAE);
  }
  canvas.drawPath(path, paint);
}

