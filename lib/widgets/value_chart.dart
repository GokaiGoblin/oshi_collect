import 'package:flutter/material.dart';

import '../theme/app_colours.dart';

/// A simple line-and-area chart of values over time, used by the value
/// summary panel (small) and the Value History page (large, with guide lines).
///
/// Light theme draws in sky blue, dark theme in gold. The latest point gets a
/// gold dot.
class ValueChart extends StatelessWidget {
  final List<double> values;
  final double height;
  final bool showGuides;

  const ValueChart({
    super.key,
    required this.values,
    required this.height,
    this.showGuides = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ValueChartPainter(
          values: values,
          line: isDark ? AppColours.gold : AppColours.lightSkyBlue,
          fill: isDark ? const Color(0x29C9A84C) : const Color(0x38B8D4EC),
          dot: isDark ? AppColours.darkPrimaryText : AppColours.gold,
          dotRing: isDark ? AppColours.darkNavBar : AppColours.lightNavWhite,
          guide: isDark ? const Color(0x26D4CEB8) : const Color(0x26F5F2FB),
          showGuides: showGuides,
        ),
      ),
    );
  }
}

class _ValueChartPainter extends CustomPainter {
  final List<double> values;
  final Color line;
  final Color fill;
  final Color dot;
  final Color dotRing;
  final Color guide;
  final bool showGuides;

  _ValueChartPainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.dot,
    required this.dotRing,
    required this.guide,
    required this.showGuides,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const dotRadius = 4.0;
    // Room at top and bottom so the line and dot never touch the edges.
    final top = dotRadius + 2;
    final bottom = size.height - dotRadius - 2;
    final left = 0.0;
    final right = size.width - dotRadius - 1;

    if (showGuides) {
      final paint = Paint()
        ..color = guide
        ..strokeWidth = 1;
      for (final y in [top, (top + bottom) / 2, bottom]) {
        for (var x = 0.0; x < size.width; x += 7) {
          canvas.drawLine(Offset(x, y), Offset(x + 3, y), paint);
        }
      }
    }

    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final span = hi - lo;
    Offset point(int i) {
      final x = values.length == 1 ? right : left + (right - left) * i / (values.length - 1);
      // A flat line sits in the middle rather than on the floor.
      final y = span == 0 ? (top + bottom) / 2 : bottom - (values[i] - lo) / span * (bottom - top);
      return Offset(x, y);
    }

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    final area = Path.from(path)
      ..lineTo(point(values.length - 1).dx, size.height)
      ..lineTo(point(0).dx, size.height)
      ..close();

    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final last = point(values.length - 1);
    canvas.drawCircle(last, dotRadius, Paint()..color = dotRing);
    canvas.drawCircle(last, dotRadius - 1.5, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_ValueChartPainter old) =>
      old.values != values || old.line != line || old.showGuides != showGuides;
}
