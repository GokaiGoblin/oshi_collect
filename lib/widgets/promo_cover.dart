import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// The artwork of a promo category tile in Portfolio → Promos: three card
// images cut into slices that soft-fade into each other ("split + wedge":
// top-left, bottom-left, and a wedge pointing in from the right).
// The layout of each category's cover is fixed data in
// lib/data/promo_covers.dart; this widget only draws it.

/// One soft edge of a layer's slice: see-through at (x0, y0), solid at
/// (x1, y1), fading across the line between the two points. Coordinates are
/// fractions of the cover (0 = left/top, 1 = right/bottom).
class CoverMask {
  final double x0, y0, x1, y1;
  const CoverMask(this.x0, this.y0, this.x1, this.y1);
}

/// One card image in a cover, back to front.
class CoverLayer {
  final int cardId;
  // Where the card image sits, as fractions of the cover's width (left,
  // width) and height (top, height). It overhangs the cover on purpose.
  final double left, top, width, height;
  // The slice's soft edges; all of them apply. Empty = the whole cover.
  final List<CoverMask> masks;
  // (position down the card, opacity) stops fading out the card's own
  // name/HP header and rules text. Empty = no fade.
  final List<(double, double)> fade;

  const CoverLayer({
    required this.cardId,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.masks = const [],
    this.fade = const [],
  });
}

class PromoCover extends StatelessWidget {
  // Width ÷ height of the cover area (178 × 232 in the approved mockups).
  static const double aspectRatio = 178 / 232;

  final List<CoverLayer> layers;
  // Card image URL by card id (cards missing from the map are skipped).
  final Map<String, String> imageUrls;

  const PromoCover({super.key, required this.layers, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final layer in layers)
                if (imageUrls[layer.cardId.toString()] case final url?)
                  _masked(
                    layer.masks,
                    // Clipped first so the overhanging card can't paint
                    // outside the cover, where the masks don't reach.
                    ClipRect(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: layer.left * w,
                            top: layer.top * h,
                            width: layer.width * w,
                            height: layer.height * h,
                            child: _faded(
                              layer.fade,
                              CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.fill,
                                memCacheWidth: (layer.width * w * pixelRatio).round(),
                                fadeInDuration: const Duration(milliseconds: 200),
                                placeholder: (_, _) => const SizedBox.shrink(),
                                errorWidget: (_, _, _) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  // Each mask multiplies the layer's opacity, so several masks keep only
  // the area inside all of them (the wedge's two edges).
  static Widget _masked(List<CoverMask> masks, Widget child) {
    var result = child;
    for (final m in masks) {
      result = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(m.x0 * 2 - 1, m.y0 * 2 - 1),
          end: Alignment(m.x1 * 2 - 1, m.y1 * 2 - 1),
          colors: const [Colors.transparent, Colors.black],
        ).createShader(bounds),
        child: result,
      );
    }
    return result;
  }

  // Top-to-bottom fade over the card image itself.
  static Widget _faded(List<(double, double)> stops, Widget child) {
    if (stops.isEmpty) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [for (final s in stops) s.$1],
        colors: [for (final s in stops) Colors.black.withValues(alpha: s.$2)],
      ).createShader(bounds),
      child: child,
    );
  }
}
