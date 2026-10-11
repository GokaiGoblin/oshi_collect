import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/price_history.dart';
import '../theme/app_colours.dart';

/// The small triangle shown next to a value to say which way it moved since
/// the previous weekly price update:
///   up   — points up, soft green
///   down — points down, soft red
///   flat — points right, white-ish
class TrendTriangle extends StatelessWidget {
  final Trend trend;
  final double size;

  const TrendTriangle({super.key, required this.trend, this.size = 8});

  /// The soft colour for [trend] in the current theme (also used for the
  /// "+¥1,500" change text next to some triangles).
  static Color colourFor(BuildContext context, Trend trend) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (trend) {
      case Trend.up:
        return isDark ? AppColours.darkTrendUp : AppColours.lightTrendUp;
      case Trend.down:
        return isDark ? AppColours.darkTrendDown : AppColours.lightTrendDown;
      case Trend.flat:
        return isDark ? AppColours.darkTrendFlat : AppColours.lightTrendFlat;
    }
  }

  static String _label(Trend trend) {
    switch (trend) {
      case Trend.up:
        return 'Value up since last update';
      case Trend.down:
        return 'Value down since last update';
      case Trend.flat:
        return 'No change since last update';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label(trend),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _TrianglePainter(trend, colourFor(context, trend)),
        ),
      ),
    );
  }
}

/// A [TrendTriangle] for one card, read from the price history. Shows nothing
/// until there are two weekly updates to compare, or if the card has no price.
class CardTrendTriangle extends StatelessWidget {
  final String cardId;
  final double size;

  const CardTrendTriangle({super.key, required this.cardId, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final trend = context.watch<PriceHistory>().data.trendFor(cardId);
    if (trend == null) return const SizedBox.shrink();
    return TrendTriangle(trend: trend, size: size);
  }
}

class _TrianglePainter extends CustomPainter {
  final Trend trend;
  final Color colour;

  const _TrianglePainter(this.trend, this.colour);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Inset slightly so the rounded stroke stays inside the box.
    final i = w * 0.1;
    final path = Path();
    switch (trend) {
      case Trend.up:
        path
          ..moveTo(w / 2, i)
          ..lineTo(w - i, h - i)
          ..lineTo(i, h - i);
        break;
      case Trend.down:
        path
          ..moveTo(i, i)
          ..lineTo(w - i, i)
          ..lineTo(w / 2, h - i);
        break;
      case Trend.flat:
        path
          ..moveTo(i, i)
          ..lineTo(w - i, h / 2)
          ..lineTo(i, h - i);
        break;
    }
    path.close();
    // Fill plus a rounded-join stroke in the same colour softens the corners.
    canvas.drawPath(path, Paint()..color = colour);
    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.12
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.trend != trend || old.colour != colour;
}
