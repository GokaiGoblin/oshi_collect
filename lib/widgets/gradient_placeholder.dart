import 'package:flutter/material.dart';

// Diagonal gradient shown in place of card/set artwork while it loads, or
// if the network request fails — colours echo the app's light/dark palettes.
class GradientPlaceholder extends StatelessWidget {
  const GradientPlaceholder({super.key});

  static const _lightColours = [
    Color(0xFFC4B8E8),
    Color(0xFFB8D4EC),
    Color(0xFFE8C4D4),
  ];
  static const _darkColours = [
    Color(0xFF1A1710),
    Color(0xFF2A2410),
    Color(0xFF1A1A0A),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? _darkColours : _lightColours,
        ),
      ),
    );
  }
}
