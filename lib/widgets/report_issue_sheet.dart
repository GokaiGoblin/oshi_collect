import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_colours.dart';

/// Modal bottom sheet for reporting issues. Matches the filter sheet style.
///
/// Pops with the string 'success' on successful submission so the caller can
/// show a confirmation snackbar. On failure the sheet stays open so the user
/// can retry without losing their typed description.
class ReportIssueSheet extends StatefulWidget {
  final String pageName;
  final String reportType;
  final String? cardDetails;

  const ReportIssueSheet({
    super.key,
    required this.pageName,
    this.reportType = 'General',
    this.cardDetails,
  });

  @override
  State<ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<ReportIssueSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  static const _formUrl =
      'https://docs.google.com/forms/d/e/'
      '1FAIpQLSdowdx1Y59Pf_-W0wdnYsD5qL1GHRVQJ04zDRb3tb-WBBKacw/formResponse';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final info = await PackageInfo.fromPlatform();
      final appVersion = '${info.version}+${info.buildNumber}';
      await http.post(
        Uri.parse(_formUrl),
        body: {
          'entry.310281904': widget.reportType,
          'entry.1081127789': widget.pageName,
          'entry.1900848456': widget.cardDetails ?? '',
          'entry.2121104535': appVersion,
          'entry.1091590823': _controller.text,
        },
      );
      if (mounted) Navigator.of(context).pop('success');
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not send — check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColour = isDark ? AppColours.darkNavBar : AppColours.lightSelectedNav;
    final handleColour = isDark ? const Color(0x60D4CEB8) : AppColours.lightFrameBorder;
    final titleColour = isDark ? AppColours.darkPrimaryText : AppColours.lightNavBar;
    final borderColour = isDark ? const Color(0x12FFFFFF) : const Color(0x4DB4A0DC);
    final hintColour = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;
    final textColour = isDark ? AppColours.darkPrimaryText : AppColours.lightNavBar;
    final fieldBg = isDark ? const Color(0x0DFFFFFF) : const Color(0x99FFFFFF);
    final fieldBorder = isDark ? const Color(0x1FFFFFFF) : AppColours.lightFrameBorder;
    final submitBg = isDark ? AppColours.darkGoldButton : AppColours.lightSkyBlue;
    final submitFg = isDark ? AppColours.gold : AppColours.lightButtonText;
    final cancelFg = isDark ? AppColours.darkMutedText : AppColours.lightMutedText;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: sheetColour,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColour,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColour, width: 0.5)),
                ),
                child: Text(
                  'Report Issue',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: titleColour),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: fieldBorder, width: 0.5),
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: !_submitting,
                    minLines: 4,
                    maxLines: 8,
                    style: TextStyle(fontSize: 13, color: textColour),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(12),
                      hintText: 'Describe the issue (optional)',
                      hintStyle: TextStyle(fontSize: 13, color: hintColour),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _submitting ? null : () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: fieldBorder, width: 0.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: cancelFg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _submitting ? null : _submit,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: submitBg,
                              borderRadius: BorderRadius.circular(10),
                              border: isDark
                                  ? Border.all(color: AppColours.darkButtonBorder, width: 0.5)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: _submitting
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: submitFg,
                                    ),
                                  )
                                : Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: submitFg,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
