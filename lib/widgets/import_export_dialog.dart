import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/catalogue_db.dart';
import '../models/owned_card_model.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colours.dart';

enum _Phase { idle, busy, importResult, exportDone, error }

class ImportExportDialog extends StatefulWidget {
  const ImportExportDialog({super.key});

  @override
  State<ImportExportDialog> createState() => _ImportExportDialogState();
}

class _ImportExportDialogState extends State<ImportExportDialog> {
  _Phase _phase = _Phase.idle;
  int _updated = 0;
  int _skipped = 0;
  String _errorMsg = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColour = isDark ? const Color(0xFF1C1A10) : AppColours.lightSelectedNav;
    final frameBorder = isDark ? AppColours.darkFrameBorder : AppColours.lightFrameBorder;
    final primary = isDark ? AppColours.darkPrimaryText : AppColours.lightNavBar;
    final secondary = isDark ? AppColours.darkSecondaryText : AppColours.lightSecondaryText;
    final muted = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
    final divider = isDark ? const Color(0x20D4CEB8) : const Color(0x44B4A0DC);

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
              'Import / Export',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Back up or restore your collection as a CSV file.',
              style: TextStyle(fontSize: 12, color: secondary),
            ),
            const SizedBox(height: 12),
            Divider(color: divider, thickness: 0.5, height: 1),
            const SizedBox(height: 14),
            _buildBody(isDark, primary, secondary, muted, divider),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    bool isDark,
    Color primary,
    Color secondary,
    Color muted,
    Color divider,
  ) {
    switch (_phase) {
      case _Phase.busy:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        );

      case _Phase.importResult:
        return _ImportResultBody(
          updated: _updated,
          skipped: _skipped,
          primary: primary,
          secondary: secondary,
          onDone: () => Navigator.of(context).pop(),
        );

      case _Phase.exportDone:
        return _MessageBody(
          text: 'Collection exported successfully.',
          textColor: primary,
          buttonLabel: 'Close',
          primary: primary,
          onTap: () => Navigator.of(context).pop(),
        );

      case _Phase.error:
        return _MessageBody(
          text: _errorMsg,
          textColor: Colors.red.shade400,
          buttonLabel: 'Dismiss',
          primary: primary,
          onTap: () => setState(() => _phase = _Phase.idle),
        );

      case _Phase.idle:
        return _IdleBody(
          isDark: isDark,
          muted: muted,
          divider: divider,
          onExport: () => _onExport(context),
          onImport: () => _onImport(context),
        );
    }
  }

  Future<void> _onExport(BuildContext context) async {
    final collection = context.read<CollectionProvider>();
    final catalogueDb = context.read<CatalogueDb>();

    if (collection.records.isEmpty) {
      setState(() {
        _phase = _Phase.error;
        _errorMsg = 'Nothing to export — claim some cards first.';
      });
      return;
    }

    setState(() => _phase = _Phase.busy);

    try {
      final allCards = await catalogueDb.getAllCards();
      final cardMap = {for (final c in allCards) c.cardId: c};

      final buf = StringBuffer('card_id,card_number,set_code,rarity,claimed,duplicates\n');
      for (final entry in collection.records.entries) {
        final card = cardMap[entry.key];
        if (card == null) continue;
        final r = entry.value;
        buf.write(
          '${entry.key},${card.cardNumber},${card.setCode},${card.rarity},'
          '${r.claimed ? 1 : 0},${r.duplicates}\n',
        );
      }

      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time =
          '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';

      final savedPath = await FilePicker.platform.saveFile(
        fileName: 'holo_tcg_collection_export_${date}_$time.csv',
        bytes: Uint8List.fromList(utf8.encode(buf.toString())),
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (!mounted) return;
      setState(() => _phase = savedPath != null ? _Phase.exportDone : _Phase.idle);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMsg = 'Export failed. Please try again.';
      });
    }
  }

  Future<void> _onImport(BuildContext context) async {
    // Capture providers before any async gap.
    final catalogueDb = context.read<CatalogueDb>();
    final collection = context.read<CollectionProvider>();

    // Open file picker before setting busy state — keeps the dialog visible
    // while the system picker is shown.
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMsg = 'Could not open file picker.';
      });
      return;
    }

    if (picked == null || picked.files.isEmpty) return; // user cancelled

    final bytes = picked.files.first.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMsg = 'Could not read the selected file.';
      });
      return;
    }

    setState(() => _phase = _Phase.busy);

    try {
      final content = utf8.decode(bytes, allowMalformed: true);
      final lines = content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.length < 2 || !lines.first.toLowerCase().startsWith('card_id')) {
        if (!mounted) return;
        setState(() {
          _phase = _Phase.error;
          _errorMsg = 'File does not appear to be a valid collection export.';
        });
        return;
      }

      final validIds = await catalogueDb.getAllCardIds();

      int updated = 0;
      int skipped = 0;
      final rows = <OwnedCardModel>[];

      for (final line in lines.skip(1)) {
        final cols = line.split(',');
        if (cols.length < 6) { skipped++; continue; }

        final cardId = cols[0].trim();
        if (!validIds.contains(cardId)) { skipped++; continue; }

        final claimed = cols[4].trim() == '1';
        final dupes = int.tryParse(cols[5].trim());
        if (dupes == null || dupes < 0) { skipped++; continue; }

        rows.add(OwnedCardModel(cardId: cardId, claimed: claimed, duplicates: dupes));
        updated++;
      }

      await collection.batchImport(rows);

      if (!mounted) return;
      setState(() {
        _phase = _Phase.importResult;
        _updated = updated;
        _skipped = skipped;
      });
    } catch (e, st) {
      debugPrint('Import error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMsg = 'Import failed. Check the file format and try again.';
      });
    }
  }
}

// ── Idle body: two action buttons + caution note ──────────────────────────────

class _IdleBody extends StatelessWidget {
  final bool isDark;
  final Color muted;
  final Color divider;
  final VoidCallback onExport;
  final VoidCallback onImport;

  const _IdleBody({
    required this.isDark,
    required this.muted,
    required this.divider,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          label: 'Export Collection',
          icon: Icons.upload_file_outlined,
          filled: true,
          isDark: isDark,
          onTap: onExport,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: 'Import Collection',
          icon: Icons.download_outlined,
          filled: false,
          isDark: isDark,
          onTap: onImport,
        ),
        const SizedBox(height: 14),
        Divider(color: divider, thickness: 0.5, height: 1),
        const SizedBox(height: 8),
        Text(
          'Importing will overwrite existing values for any cards listed in the '
          'file. Cards not listed remain unchanged.',
          style: TextStyle(fontSize: 10, color: muted),
        ),
      ],
    );
  }
}

// ── Import result ─────────────────────────────────────────────────────────────

class _ImportResultBody extends StatelessWidget {
  final int updated;
  final int skipped;
  final Color primary;
  final Color secondary;
  final VoidCallback onDone;

  const _ImportResultBody({
    required this.updated,
    required this.skipped,
    required this.primary,
    required this.secondary,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$updated card${updated == 1 ? '' : 's'} updated.',
          style: TextStyle(fontSize: 13, color: primary),
        ),
        if (skipped > 0) ...[
          const SizedBox(height: 4),
          Text(
            '$skipped row${skipped == 1 ? '' : 's'} skipped (invalid card ID or data).',
            style: TextStyle(fontSize: 12, color: secondary),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onDone,
            child: Text('Done', style: TextStyle(color: primary)),
          ),
        ),
      ],
    );
  }
}

// ── Generic inline message (export done / error) ──────────────────────────────

class _MessageBody extends StatelessWidget {
  final String text;
  final Color textColor;
  final String buttonLabel;
  final Color primary;
  final VoidCallback onTap;

  const _MessageBody({
    required this.text,
    required this.textColor,
    required this.buttonLabel,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: TextStyle(fontSize: 13, color: textColor)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onTap,
            child: Text(buttonLabel, style: TextStyle(color: primary)),
          ),
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg, fg, borderColor;
    if (isDark) {
      bg = filled ? AppColours.darkNavBar : Colors.transparent;
      fg = AppColours.darkSelectedNav;
      borderColor = filled ? AppColours.darkSelectedNav : const Color(0x80D4CEB8);
    } else {
      bg = filled ? AppColours.lightNavBar : Colors.transparent;
      fg = filled ? AppColours.lightSelectedNav : AppColours.lightNavBar;
      borderColor = filled ? AppColours.lightNavBar : const Color(0x80544D85);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
