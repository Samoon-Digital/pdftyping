import 'package:flutter/material.dart';
import 'dart:async';

// ── Show the web PDF success dialog (call after kIsWeb PDF generation) ──
/// Dismisses the loading dialog, then shows a centered popup with a Download
/// button.  Future: replace the onDownload body with a reward-ad / AdSense
/// full-screen before triggering the download.
Future<void> showWebPdfSuccessDialog(
  BuildContext context, {
  required String fileName,
  required Future<void> Function() onDownload,
}) async {
  // Dismiss the PdfGeneratingDialog that is still on screen.
  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) =>
        _WebPdfSuccessDialog(fileName: fileName, onDownload: onDownload),
  );
}

// ── Loading dialog shown while PDF is being rendered & saved ──
class PdfGeneratingDialog extends StatefulWidget {
  const PdfGeneratingDialog({super.key});

  @override
  State<PdfGeneratingDialog> createState() => _PdfGeneratingDialogState();
}

class _PdfGeneratingDialogState extends State<PdfGeneratingDialog> {
  static const _steps = [
    'दस्तावेज तैयार हो रहा है…',
    'छवि बनाई जा रही है…',
    'PDF फ़ाइल बन रही है…',
    'फ़ाइल सहेजी जा रही है…',
  ];
  int _stepIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (mounted) setState(() => _stepIndex = (_stepIndex + 1) % _steps.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PDF बन रही है…',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 13,
                    color: Color(0xFF616161),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == _stepIndex ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= _stepIndex
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFBBDEFB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Success bottom sheet shown after PDF is saved ──
class PdfSuccessSheet extends StatelessWidget {
  final String fileName;
  final VoidCallback onViewSaved;
  final VoidCallback onMakeAnother;

  const PdfSuccessSheet({
    super.key,
    required this.fileName,
    required this.onViewSaved,
    required this.onMakeAnother,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ──
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Success icon ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ──
            const Text(
              'PDF सेव हो गई!',
              style: TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),

            const SizedBox(height: 8),

            // ── File name chip ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 15,
                    color: Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'आपका आवेदन Saved टैब में मिलेगा।',
              style: TextStyle(
                fontFamily: 'NotoSansDevanagari',
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // ── Primary CTA ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onViewSaved,
                icon: const Icon(Icons.bookmark_rounded, size: 20),
                label: const Text(
                  'Saved में देखें',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Secondary CTA ──
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: onMakeAnother,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF757575),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'और आवेदन बनाएं',
                  style: TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Web-only: centered dialog shown after PDF is generated ──
class _WebPdfSuccessDialog extends StatefulWidget {
  final String fileName;
  final Future<void> Function() onDownload;

  const _WebPdfSuccessDialog({
    required this.fileName,
    required this.onDownload,
  });

  @override
  State<_WebPdfSuccessDialog> createState() => _WebPdfSuccessDialogState();
}

class _WebPdfSuccessDialogState extends State<_WebPdfSuccessDialog> {
  bool _downloading = false;

  Future<void> _handleDownload() async {
    // ─── Future ad hook ────────────────────────────────────────────────────
    // To show a reward ad or AdSense full-screen before download, insert the
    // ad-display logic here before calling widget.onDownload().
    // ───────────────────────────────────────────────────────────────────────
    setState(() => _downloading = true);
    try {
      await widget.onDownload();
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Success icon ──
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 20),

              // ── Title ──
              const Text(
                'PDF तैयार है!',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),

              const SizedBox(height: 8),

              // ── File name ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 15,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.fileName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF616161),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Download CTA ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _downloading ? null : _handleDownload,
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 22),
                  label: Text(
                    _downloading ? 'डाउनलोड हो रही है…' : 'PDF डाउनलोड करें',
                    style: const TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Close / Make another ──
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: _downloading
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF757575),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'और आवेदन बनाएं',
                    style: TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 14,
                    ),
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
