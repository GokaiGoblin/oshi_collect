import 'package:flutter/material.dart';
import '../theme/app_colours.dart';

// Small 10×10px diamond-shaped duplicate indicator shown in the top-right
// corner of a card's info panel (Catalogue / Portfolio). Must be placed
// inside a Stack — it positions itself per the design spec (top: 8, right: 5).
class DupeDot extends StatelessWidget {
  const DupeDot({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      right: 5,
      child: SizedBox(
        width: 10,
        height: 10,
        child: CustomPaint(
          painter: _DiamondDotPainter(),
        ),
      ),
    );
  }
}

class _DiamondDotPainter extends CustomPainter {
  const _DiamondDotPainter();

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
    canvas.drawPath(
      path,
      Paint()..color = AppColours.lightDupePink,
    );
  }

  @override
  bool shouldRepaint(_DiamondDotPainter old) => false;
}
