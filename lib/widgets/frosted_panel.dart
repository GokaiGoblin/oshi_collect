import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colours.dart';

// Soft dark halo behind light-theme panel text.
const _lightTextShadows = [
  Shadow(color: Color(0x73000000), blurRadius: 3),
];

class FrostedPanel extends StatelessWidget {
  /// How strongly panels blur the background behind them. Kept light (was 6, then 2)
  /// so the triangle background shows through. Also used by the Portfolio
  /// All / Owned / Unowned control.
  static const double blurSigma = 1;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  // Overrides the theme's default frosted-panel background (and therefore its
  // opacity) — e.g. card info panels use a higher-opacity tint than general panels.
  final Color? backgroundColor;

  const FrostedPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColours.darkFrostedPanel : AppColours.lightFrostedPanel);
    final br = borderRadius ?? BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(color: bgColor, borderRadius: br),
          padding: padding ?? const EdgeInsets.all(12),
          // Light theme: a soft shadow behind all text in the panel, so it
          // stays readable over the bright background with a lighter panel.
          child: isDark
              ? child
              : DefaultTextStyle.merge(
                  style: const TextStyle(shadows: _lightTextShadows),
                  child: child,
                ),
        ),
      ),
    );
  }
}
