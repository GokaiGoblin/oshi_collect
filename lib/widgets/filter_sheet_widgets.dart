import 'package:flutter/material.dart';

import '../theme/app_colours.dart';

/// Shared building blocks for the Catalogue and Inventory filter sheets —
/// both follow the same frosted, pill-chip design from the mockups, differing
/// only in which filter sections they show and what each chip does when
/// tapped. Keeping the chrome here means that design only needs maintaining
/// in one place.

const List<String> standardRarities = ['C', 'U', 'S', 'R', 'RR'];
const List<String> goldRarities = ['SR', 'UR', 'HR', 'OSR', 'OUR', 'SEC', 'SY', 'P'];

/// One Archetype chip's colour dot — differs between light and dark themes,
/// and "Support" has no dot at all (both null).
class ArchetypeDotOption {
  final String label;
  final Color? lightDot;
  final Color? lightBorder;
  final Color? darkDot;
  final Color? darkBorder;

  const ArchetypeDotOption(
    this.label, {
    this.lightDot,
    this.lightBorder,
    this.darkDot,
    this.darkBorder,
  });
}

const List<ArchetypeDotOption> archetypeOptions = [
  ArchetypeDotOption(
    'White',
    lightDot: Color(0xFFE8E8E8), lightBorder: Color(0xFFC4B8E8),
    darkDot: Color(0xFF4A4A4A), darkBorder: Color(0xFF888888),
  ),
  ArchetypeDotOption('Green', lightDot: Color(0xFF4CAF7A), darkDot: Color(0xFF2E6B47)),
  ArchetypeDotOption('Red', lightDot: Color(0xFFE05555), darkDot: Color(0xFF8B3030)),
  ArchetypeDotOption('Blue', lightDot: Color(0xFF5588E0), darkDot: Color(0xFF2A4A8A)),
  ArchetypeDotOption('Purple', lightDot: Color(0xFF9B6BAE), darkDot: Color(0xFF5A3A6A)),
  ArchetypeDotOption('Yellow', lightDot: Color(0xFFE0C040), darkDot: Color(0xFF8A7020)),
  ArchetypeDotOption('Support'),
];

/// One chip's appearance + behaviour. The `gold` variant is used for the
/// rare/secret rarity tiers; `dot` renders an Archetype colour swatch.
class FilterChipData {
  final String label;
  final bool active;
  final bool gold;
  final ArchetypeDotOption? dot;
  final VoidCallback onTap;

  const FilterChipData({
    required this.label,
    required this.active,
    this.gold = false,
    this.dot,
    required this.onTap,
  });
}

/// A labelled group of chips — one row in the sheet (Owned, Rarity, etc).
class FilterSection {
  final String label;
  final List<FilterChipData> chips;

  const FilterSection({required this.label, required this.chips});
}

/// The sheet itself: handle, title + "Reset all", each filter section
/// (separated by hairline dividers), and a full-width Apply button.
class FilterSheetScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onResetAll;
  final List<FilterSection> sections;
  final String applyLabel;
  final VoidCallback onApply;

  const FilterSheetScaffold({
    super.key,
    required this.title,
    required this.onResetAll,
    required this.sections,
    required this.applyLabel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColour = isDark ? AppColours.darkNavBar : AppColours.lightSelectedNav;
    final handleColour = isDark ? const Color(0x60D4CEB8) : AppColours.lightFrameBorder;

    return Container(
      decoration: BoxDecoration(
        color: sheetColour,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: handleColour, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              _SheetHeader(title: title, onResetAll: onResetAll),
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const _SectionDivider(),
                _FilterSectionView(section: sections[i]),
              ],
              const SizedBox(height: 12),
              _ApplyButton(label: applyLabel, onTap: onApply),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onResetAll;

  const _SheetHeader({required this.title, required this.onResetAll});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColour = isDark ? AppColours.darkPrimaryText : AppColours.lightNavBar;
    final resetColour = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
    final borderColour = isDark ? const Color(0x12FFFFFF) : const Color(0x4DB4A0DC);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColour, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: titleColour)),
          Semantics(
            label: 'Reset all filters',
            button: true,
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onResetAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Text('Reset all', style: TextStyle(fontSize: 11, color: resetColour)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isDark ? const Color(0x12FFFFFF) : const Color(0x33B4A0DC),
    );
  }
}

class _FilterSectionView extends StatelessWidget {
  final FilterSection section;

  const _FilterSectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColour = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: labelColour,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final chip in section.chips) _FilterChip(data: chip)],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final FilterChipData data;

  const _FilterChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background;
    final Color textColour;
    final Color borderColour;

    if (data.gold) {
      if (data.active) {
        background = isDark ? AppColours.darkButtonBorder : AppColours.gold;
        textColour = isDark ? AppColours.darkPrimaryText : Colors.white;
        borderColour = AppColours.gold;
      } else {
        background = isDark ? const Color(0x0DFFFFFF) : const Color(0x99FFFFFF);
        textColour = isDark ? AppColours.gold : const Color(0xFFA8873A);
        borderColour = isDark ? AppColours.darkButtonBorder : AppColours.gold;
      }
    } else if (data.active) {
      background = isDark ? const Color(0xFF2E2450) : AppColours.lightNavBar;
      textColour = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;
      borderColour = isDark ? AppColours.darkSelectedNav : AppColours.lightNavBar;
    } else {
      background = isDark ? const Color(0x0DFFFFFF) : const Color(0x99FFFFFF);
      textColour = isDark ? const Color(0xFFA09880) : AppColours.lightSecondaryText;
      borderColour = isDark ? const Color(0x1FFFFFFF) : AppColours.lightFrameBorder;
    }

    final dot = data.dot;
    final dotColour = dot == null ? null : (isDark ? dot.darkDot : dot.lightDot);
    final dotBorder = dot == null ? null : (isDark ? dot.darkBorder : dot.lightBorder);

    return Semantics(
      label: '${data.label}${data.active ? ", selected" : ""}',
      button: true,
      selected: data.active,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColour, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColour != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColour,
                        shape: BoxShape.circle,
                        border: dotBorder != null ? Border.all(color: dotBorder, width: 1) : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(data.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColour)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ApplyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0x1AD4CEB8) : AppColours.lightSkyBlue;
    final foreground = isDark ? AppColours.darkSelectedNav : AppColours.lightButtonText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
              border: isDark ? Border.all(color: AppColours.darkSelectedNav, width: 0.5) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: foreground, letterSpacing: 0.02),
            ),
          ),
        ),
      ),
    );
  }
}
