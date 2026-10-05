import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/card_model.dart';
import '../../providers/catalogue_provider.dart';
import '../../providers/collection_provider.dart';
import '../../theme/app_colours.dart';
import '../../widgets/card_artwork_image.dart';
import '../../widgets/frosted_panel.dart';
import '../../widgets/app_background.dart';
import '../../widgets/rarity_badge.dart';
import '../../providers/preferences_provider.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/settings_menu.dart';

class CardProfilePage extends StatefulWidget {
  final List<CardModel> cards;
  final int initialIndex;

  const CardProfilePage({
    super.key,
    required this.cards,
    required this.initialIndex,
  });

  @override
  State<CardProfilePage> createState() => _CardProfilePageState();
}

class _CardProfilePageState extends State<CardProfilePage> {
  late int _currentIndex;

  // Raw pointer tracking for swipe navigation.
  // Using Listener (not GestureDetector) bypasses the gesture arena so
  // SingleChildScrollView's VerticalDragRecognizer can't block horizontal swipes.
  double? _swipeStartX;
  double? _swipeStartY;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  CardModel get _card => widget.cards[_currentIndex];

  void _navigate(int delta) {
    final next = _currentIndex + delta;
    if (next < 0 || next >= widget.cards.length) return;
    setState(() => _currentIndex = next);
  }

  void _onPointerDown(PointerDownEvent e) {
    _swipeStartX = e.position.dx;
    _swipeStartY = e.position.dy;
  }

  void _onPointerUp(PointerUpEvent e) {
    final startX = _swipeStartX;
    final startY = _swipeStartY;
    _swipeStartX = null;
    _swipeStartY = null;
    if (startX == null || startY == null) return;

    final dx = e.position.dx - startX;
    final dy = e.position.dy - startY;

    // Must be a clearly horizontal gesture (more X than Y) and long enough
    // to distinguish from a tap. Taps have tiny dx and won't reach 50px.
    if (dx.abs() < 50) return;
    if (dy.abs() >= dx.abs()) return;

    if (dx < 0) {
      _navigate(1);   // swipe left → next card
    } else {
      _navigate(-1);  // swipe right → previous card
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: (_) { _swipeStartX = null; _swipeStartY = null; },
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _ProfileNavBar(card: _card),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ArtworkSection(
                      card: _card,
                      onPrevious: () => _navigate(-1),
                      onNext: () => _navigate(1),
                      hasPrevious: _currentIndex > 0,
                      hasNext: _currentIndex < widget.cards.length - 1,
                    ),
                    // Rarity badge centred below artwork.
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 14),
                      child: Center(child: RarityBadge(card: _card)),
                    ),
                    // Claim / Claimed button — constrained to 200 px so it
                    // never spans the full page width on large screens.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                      child: Center(
                        child: SizedBox(
                          width: 200,
                          child: _ClaimButton(card: _card),
                        ),
                      ),
                    ),
                    _InfoPanel(card: _card),
                    _DuplicatesPanel(card: _card),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────

String _rarityLabel(CardModel card) =>
    card.isFoil ? '${card.rarity} · Foil' : card.rarity;

// ── Nav bar ─────────────────────────────────────────────────────────────────

class _ProfileNavBar extends StatelessWidget {
  final CardModel card;
  const _ProfileNavBar({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColour = isDark ? AppColours.darkNavBar : AppColours.lightNavBar;
    final navText = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;

    return Container(
      color: navColour,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                label: 'Back',
                button: true,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(child: Icon(Icons.arrow_back, size: 18, color: navText)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.nameJp,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: navText,
                          height: 1.3,
                        ),
                      ),
                      if (card.nameEn != null)
                        Text(
                          card.nameEn!,
                          style: TextStyle(
                            fontSize: 11,
                            color: navText.withValues(alpha: 0.75),
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text(
                'Card Profile',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navText),
              ),
              const SizedBox(width: 16),
              SettingsMenu(
                iconColor: navText,
                pageName: 'Card Profile',
                reportType: 'Card Data',
                cardDetails: '${card.cardId} | ${card.cardNumber} | ${card.setCode} | ${card.rarity} | ${card.nameEn ?? ''}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Artwork section ──────────────────────────────────────────────────────────

class _ArtworkSection extends StatelessWidget {
  static const double _cardRatio = 0.714; // ~63×88mm trading card

  final CardModel card;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool hasPrevious;
  final bool hasNext;

  const _ArtworkSection({
    required this.card,
    required this.onPrevious,
    required this.onNext,
    required this.hasPrevious,
    required this.hasNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final artworkWidth = constraints.maxWidth * 0.70;
          final sideWidth = (constraints.maxWidth - artworkWidth) / 2;
          final artworkHeight = artworkWidth / _cardRatio;

          return SizedBox(
            height: artworkHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left tap zone — previous card.
                // Visible chevron for sighted users; Semantics label for TalkBack.
                Semantics(
                  label: 'Previous card',
                  button: hasPrevious,
                  enabled: hasPrevious,
                  excludeSemantics: true,
                  onTap: hasPrevious ? onPrevious : null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPrevious,
                    child: SizedBox(
                      width: sideWidth,
                      child: hasPrevious
                          ? Center(
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                // Artwork — opens full-screen on tap.
                // Swipe navigation is handled by the page-level Listener.
                // rootNavigator: true so the fullscreen view covers the bottom nav.
                GestureDetector(
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => _FullScreenArtworkPage(card: card),
                    ),
                  ),
                  child: SizedBox(
                    width: artworkWidth,
                    height: artworkHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CardArtworkImage(
                        card: card,
                        placeholder: (_) => _ArtworkPlaceholder(card: card),
                        errorWidget: (_) => _ArtworkPlaceholder(card: card),
                      ),
                    ),
                  ),
                ),
                // Right tap zone — next card.
                Semantics(
                  label: 'Next card',
                  button: hasNext,
                  enabled: hasNext,
                  excludeSemantics: true,
                  onTap: hasNext ? onNext : null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onNext,
                    child: SizedBox(
                      width: sideWidth,
                      child: hasNext
                          ? Center(
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  final CardModel card;
  const _ArtworkPlaceholder({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
    final placeholderBg = isDark ? const Color(0xD91E1A10) : const Color(0xD9EAE0F0);
    final placeholderBorder = isDark ? const Color(0x14FFFFFF) : AppColours.lightFrameBorder;

    return Container(
      decoration: BoxDecoration(
        color: placeholderBg,
        border: Border.all(color: placeholderBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        'Card Artwork\n${card.cardNumber}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: muted),
      ),
    );
  }
}

// Full-screen artwork view — tapping anywhere or pressing back dismisses it.
class _FullScreenArtworkPage extends StatelessWidget {
  static const double _cardRatio = 0.714;

  final CardModel card;
  const _FullScreenArtworkPage({required this.card});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth * 0.88;
                  final maxH = constraints.maxHeight * 0.88;
                  final widthFromHeight = maxH * _cardRatio;
                  final w = widthFromHeight < maxW ? widthFromHeight : maxW;
                  return SizedBox(
                    width: w,
                    child: AspectRatio(
                      aspectRatio: _cardRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CardArtworkImage(
                          card: card,
                          fit: BoxFit.contain,
                          placeholder: (_) => _ArtworkPlaceholder(card: card),
                          errorWidget: (_) => _ArtworkPlaceholder(card: card),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Claim button ─────────────────────────────────────────────────────────────

class _ClaimButton extends StatelessWidget {
  final CardModel card;
  const _ClaimButton({required this.card});

  @override
  Widget build(BuildContext context) {
    final claimed = context.watch<CollectionProvider>().isClaimed(card.cardId);
    return claimed ? _buildClaimedButton(context) : _buildClaimButton(context);
  }

  Widget _buildClaimButton(BuildContext context) {
    return Semantics(
      label: 'Claim card',
      button: true,
      excludeSemantics: true,
      child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => context.read<CollectionProvider>().claim(card.cardId),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0D070), Color(0xFFC9A84C), Color(0xFF8A6820)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6A5010), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '✦ Claim',
            style: TextStyle(
              color: Color(0xFF3A2808),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildClaimedButton(BuildContext context) {
    return Semantics(
      label: 'Claimed, double tap to unclaim',
      button: true,
      excludeSemantics: true,
      child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _showUnclaimDialog(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC8D0D8), Color(0xFFA8B0B8), Color(0xFF888898)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF606878), width: 1),
          ),
          alignment: Alignment.center,
          child: const Text(
            '✓ Claimed',
            style: TextStyle(
              color: Color(0xFF383848),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _showUnclaimDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _UnclaimDialog(isDark: isDark),
    );
    if (confirmed == true && context.mounted) {
      await context.read<CollectionProvider>().unclaim(card.cardId);
    }
  }
}

// ── Unclaim confirmation dialog ──────────────────────────────────────────────

class _UnclaimDialog extends StatelessWidget {
  final bool isDark;
  const _UnclaimDialog({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColours.darkPrimaryText : AppColours.lightNavBar;
    final secondary = isDark ? AppColours.darkSecondaryText : AppColours.lightSecondaryText;
    final sheetColour = isDark ? const Color(0xFF1C1A10) : AppColours.lightSelectedNav;
    final frameBorder = isDark ? AppColours.darkFrameBorder : AppColours.lightFrameBorder;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: sheetColour,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: frameBorder, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove from collection?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This will unclaim the card. Your duplicate count will be preserved.',
              style: TextStyle(fontSize: 12, color: secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    bgColour: isDark ? AppColours.darkGoldButton : AppColours.lightSkyBlue,
                    textColour: isDark ? AppColours.gold : AppColours.lightButtonText,
                    borderColour: isDark ? AppColours.darkButtonBorder : null,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Confirm',
                    bgColour: isDark ? AppColours.darkDupePink : AppColours.lightDupePink,
                    textColour: Colors.white,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color bgColour;
  final Color textColour;
  final Color? borderColour;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.bgColour,
    required this.textColour,
    required this.onTap,
    this.borderColour,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bgColour,
            borderRadius: BorderRadius.circular(8),
            border: borderColour != null
                ? Border.all(color: borderColour!, width: 0.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColour),
          ),
        ),
      ),
    );
  }
}

// ── Info panel ───────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final CardModel card;
  const _InfoPanel({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Light: navWhite labels/values over frosted panel. Dark: themed colours.
    final labelColor = isDark ? AppColours.darkPrimaryText : AppColours.lightNavWhite;
    final valueColor = isDark ? AppColours.darkSecondaryText : AppColours.lightNavWhite;
    final mutedColor = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
    final divider = isDark ? const Color(0x12FFFFFF) : const Color(0x4DB4A0DC);

    final sets = context.watch<CatalogueProvider>().sets;
    final setName = sets.where((s) => s.code == card.setCode).firstOrNull?.name ?? card.setCode;
    final prefs = context.watch<PreferencesProvider>();

    final rows = <(String label, String value, Color valueColor)>[
      ('Japanese name', card.nameJp, valueColor),
      if (card.nameEn != null) ('English name', card.nameEn!, valueColor),
      ('Card number', card.cardNumber, valueColor),
      ('Set', setName, valueColor),
      ('Rarity', _rarityLabel(card), AppColours.gold),
      ('Estimated value', formatPrice(card.priceUsd, prefs.currencyCode, prefs.fxRates), AppColours.gold),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
      child: FrostedPanel(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: i == rows.length - 1
                    ? null
                    : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: divider, width: 0.5),
                        ),
                      ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rows[i].$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          rows[i].$2,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: rows[i].$3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (prefs.fxRatesUpdatedAt == null && prefs.currencyCode != 'USD')
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Text(
                  'Exchange rates unavailable — showing USD',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 9.5, color: mutedColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Duplicates panel ─────────────────────────────────────────────────────────

class _DuplicatesPanel extends StatelessWidget {
  final CardModel card;
  const _DuplicatesPanel({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dupePink = isDark ? AppColours.darkDupePink : AppColours.lightDupePink;

    final collection = context.watch<CollectionProvider>();
    final claimed = collection.isClaimed(card.cardId);
    final duplicates = collection.duplicateCount(card.cardId);

    final canDecrement = claimed && duplicates > 0;
    final canIncrement = claimed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 12),
      child: FrostedPanel(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Duplicates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: dupePink,
              ),
            ),
            // Button order: − / count / +
            Row(
              children: [
                _DupeButton(
                  label: '−',
                  semanticsLabel: 'Decrease duplicate count, currently $duplicates',
                  enabled: canDecrement,
                  onTap: () => context.read<CollectionProvider>().decrementDuplicates(card.cardId),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$duplicates',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: dupePink,
                    ),
                  ),
                ),
                _DupeButton(
                  label: '+',
                  semanticsLabel: 'Increase duplicate count, currently $duplicates',
                  enabled: canIncrement,
                  onTap: () => context.read<CollectionProvider>().incrementDuplicates(card.cardId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DupeButton extends StatelessWidget {
  final String label;
  final String semanticsLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _DupeButton({
    required this.label,
    required this.semanticsLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColour = isDark ? AppColours.darkGoldButton : AppColours.lightSkyBlue;
    final fgColour = isDark ? AppColours.gold : AppColours.lightButtonText;

    return Semantics(
      label: semanticsLabel,
      button: enabled,
      enabled: enabled,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.38,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColour,
                    shape: BoxShape.circle,
                    border: isDark ? Border.all(color: AppColours.darkButtonBorder) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: fgColour,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

