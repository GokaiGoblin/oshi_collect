import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

import '../db/price_updates.dart';
import '../providers/collection_provider.dart';
import '../providers/preferences_provider.dart';
import '../theme/app_colours.dart';
import '../utils/build_info.dart';
import 'import_export_dialog.dart';
import 'report_issue_sheet.dart';

enum _MenuAction { cardView, theme, currency, report, importExport, resetData }

class SettingsMenu extends StatelessWidget {
  final Color iconColor;
  final bool showCardViewToggle;
  final String pageName;
  final String reportType;
  final String? cardDetails;

  const SettingsMenu({
    super.key,
    required this.iconColor,
    required this.pageName,
    this.showCardViewToggle = false,
    this.reportType = 'General',
    this.cardDetails,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final isDark = prefs.themeMode == ThemeMode.dark;
    final cols = prefs.cardViewColumns;
    final menuIconColour = isDark ? AppColours.darkSelectedNav : AppColours.lightSelectedNav;

    return PopupMenuButton<_MenuAction>(
      tooltip: 'Options',
      offset: const Offset(0, 36),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _MenuAction.cardView:
            prefs.toggleCardViewColumns();
          case _MenuAction.theme:
            prefs.toggleTheme();
          case _MenuAction.currency:
            showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (_) => const _CurrencyDialog(),
            );
          case _MenuAction.report:
            showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ReportIssueSheet(
                pageName: pageName,
                reportType: reportType,
                cardDetails: cardDetails,
              ),
            ).then((result) {
              if (result == 'success' && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report sent — thank you'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            });
          case _MenuAction.importExport:
            showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (_) => const ImportExportDialog(),
            );
          case _MenuAction.resetData:
            showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (_) => const _ResetDialog(),
            );
        }
      },
      itemBuilder: (_) => [
        if (showCardViewToggle) ...[
          PopupMenuItem<_MenuAction>(
            value: _MenuAction.cardView,
            child: Row(
              children: [
                Icon(Icons.auto_awesome_mosaic, size: 18, color: menuIconColour),
                const SizedBox(width: 8),
                Text(cols == 3 ? '2-Card View' : '3-Card View'),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.theme,
          child: Row(
            children: [
              Icon(isDark ? Icons.wb_sunny_outlined : Icons.star_outline, size: 18, color: menuIconColour),
              const SizedBox(width: 8),
              Text(isDark ? 'Light Mode' : 'Dark Mode'),
            ],
          ),
        ),
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.currency,
          child: Row(
            children: [
              Icon(Icons.attach_money, size: 18, color: menuIconColour),
              const SizedBox(width: 8),
              const Text('Currency'),
            ],
          ),
        ),
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.report,
          child: Row(
            children: [
              Icon(Icons.bug_report_outlined, size: 18, color: menuIconColour),
              const SizedBox(width: 8),
              const Text('Report'),
            ],
          ),
        ),
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.importExport,
          child: Row(
            children: [
              Icon(Icons.import_export, size: 18, color: menuIconColour),
              const SizedBox(width: 8),
              const Text('Import / Export'),
            ],
          ),
        ),
        if (!kReleaseMode) ...[
          const PopupMenuDivider(),
          PopupMenuItem<_MenuAction>(
            value: _MenuAction.resetData,
            child: const Row(
              children: [
                Icon(Icons.delete_forever_outlined, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Reset App Data', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        const PopupMenuItem<_MenuAction>(
          enabled: false,
          height: 28,
          child: Text(
            'Version $kAppVersion',
            style: TextStyle(fontSize: 10),
          ),
        ),
      ],
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(child: Icon(Icons.more_horiz, size: 20, color: iconColor)),
      ),
    );
  }
}

// ── Reset App Data dialog ─────────────────────────────────────────────────────

class _ResetDialog extends StatelessWidget {
  const _ResetDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColour = isDark ? const Color(0xFF1C1A10) : AppColours.lightSelectedNav;
    final frameBorder = isDark ? AppColours.darkFrameBorder : AppColours.lightFrameBorder;
    final primary = isDark ? AppColours.darkPrimaryText : AppColours.lightNavBar;
    final secondary = isDark ? AppColours.darkSecondaryText : AppColours.lightSecondaryText;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: sheetColour,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: frameBorder, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset App Data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will clear all claimed cards, duplicates, cached images, and preferences. This cannot be undone.',
              style: TextStyle(fontSize: 13, color: secondary),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: primary)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    // Capture providers before popping — context may be
                    // unavailable once the dialog is dismissed.
                    final collection = context.read<CollectionProvider>();
                    final prefs = context.read<PreferencesProvider>();
                    Navigator.of(context).pop();
                    await collection.resetAll();
                    await prefs.resetAll();
                    PaintingBinding.instance.imageCache.clear();
                    await DefaultCacheManager().emptyCache();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.12),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
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

// ── Currency selector dialog ──────────────────────────────────────────────────

class _CurrencyDialog extends StatelessWidget {
  const _CurrencyDialog();

  static const _currencies = [
    ('USD', '\$'),
    ('GBP', '£'),
    ('EUR', '€'),
    ('JPY', '¥'),
    ('AUD', 'A\$'),
    ('CAD', 'C\$'),
  ];

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primary = isDark ? AppColours.darkPrimaryText : AppColours.lightNavBar;
    final secondary = isDark ? AppColours.darkSecondaryText : AppColours.lightSecondaryText;
    final sheetColour = isDark ? const Color(0xFF1C1A10) : AppColours.lightSelectedNav;
    final frameBorder = isDark ? AppColours.darkFrameBorder : AppColours.lightFrameBorder;
    final dividerColour = isDark ? const Color(0x20D4CEB8) : const Color(0x44B4A0DC);

    final selectedBorder = isDark ? AppColours.gold : const Color(0xFF544D85);
    final selectedBg = isDark ? const Color(0x1FC9A84C) : const Color(0x38544D85);
    final unselectedBg = isDark ? const Color(0x0DFFFFFF) : const Color(0x12544D85);

    final pricesOn = context.watch<PriceUpdates>().updatedOn;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final pricesText = pricesOn == null
        ? 'Card prices: as built into this app version.'
        : 'Card prices as of ${pricesOn.day} ${months[pricesOn.month - 1]} ${pricesOn.year}.';

    final updatedAt = prefs.fxRatesUpdatedAt;
    final String lastUpdatedText;
    if (updatedAt == null) {
      lastUpdatedText = 'Not yet updated.';
    } else {
      final hours =
          ((DateTime.now().millisecondsSinceEpoch - updatedAt) / 3600000).floor();
      lastUpdatedText = 'Last updated ${hours}h ago.';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: sheetColour,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: frameBorder, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Currency',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Select the currency for all prices in the app.',
              style: TextStyle(fontSize: 12, color: secondary),
            ),
            const SizedBox(height: 12),
            Divider(color: dividerColour, thickness: 0.5, height: 1),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: [
                for (final (code, symbol) in _currencies)
                  _CurrencyPill(
                    code: code,
                    symbol: symbol,
                    isSelected: prefs.currencyCode == code,
                    selectedBorder: selectedBorder,
                    selectedBg: selectedBg,
                    unselectedBg: unselectedBg,
                    textColor: primary,
                    onTap: () {
                      prefs.setCurrency(code);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: dividerColour, thickness: 0.5, height: 1),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Exchange rates update on start-up, once every 24 hours.',
                    style: TextStyle(fontSize: 9.5, color: secondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lastUpdatedText,
                  style: TextStyle(fontSize: 9.5, color: secondary),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(pricesText, style: TextStyle(fontSize: 9.5, color: secondary)),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final String code;
  final String symbol;
  final bool isSelected;
  final Color selectedBorder;
  final Color selectedBg;
  final Color unselectedBg;
  final Color textColor;
  final VoidCallback onTap;

  const _CurrencyPill({
    required this.code,
    required this.symbol,
    required this.isSelected,
    required this.selectedBorder,
    required this.selectedBg,
    required this.unselectedBg,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: code,
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: selectedBorder, width: 1) : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              Text(
                code,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
