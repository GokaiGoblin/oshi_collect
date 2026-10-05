import 'package:flutter/material.dart';

/// Displays the app's pre-composited background image (gradient + triangle
/// texture, baked into a single PNG per theme) filling the entire screen.
///
/// Wrap the Scaffold (not just its body) so the image extends edge-to-edge:
///   AppBackground(
///     child: Scaffold(
///       backgroundColor: Colors.transparent,
///       body: ...,
///     ),
///   )
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/bg/bg_final_dark.png'
        : 'assets/bg/bg_final_light.png';

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
        child,
      ],
    );
  }
}
