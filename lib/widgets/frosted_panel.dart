import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colours.dart';

class FrostedPanel extends StatelessWidget {
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
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(color: bgColor, borderRadius: br),
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}
