import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/card_model.dart';

/// Displays a card's artwork, falling back to [errorWidget] if the URL fails.
class CardArtworkImage extends StatefulWidget {
  final CardModel card;
  final BoxFit fit;
  final WidgetBuilder placeholder;
  final WidgetBuilder errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CardArtworkImage({
    super.key,
    required this.card,
    this.fit = BoxFit.cover,
    required this.placeholder,
    required this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  State<CardArtworkImage> createState() => _CardArtworkImageState();
}

class _CardArtworkImageState extends State<CardArtworkImage> {
  int _urlIndex = 0;

  List<String> get _urls => [widget.card.imageUrl];

  @override
  void didUpdateWidget(CardArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the chain when the card changes (e.g. grid recycling).
    if (oldWidget.card.cardId != widget.card.cardId) {
      setState(() => _urlIndex = 0);
    }
  }

  void _advance() {
    Future.microtask(() {
      if (mounted) setState(() => _urlIndex++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    final url = urls[_urlIndex];

    return CachedNetworkImage(
      // ValueKey forces a fresh CachedNetworkImage instance on each URL change.
      key: ValueKey(url),
      imageUrl: url,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      placeholder: (ctx, _) => widget.placeholder(ctx),
      errorWidget: (ctx, url, err) {
        if (_urlIndex < urls.length - 1) {
          _advance();
          return widget.placeholder(ctx);
        }
        return widget.errorWidget(ctx);
      },
    );
  }
}
