import 'package:flutter/material.dart';

// ── Loading dialog shown while PDF is being rendered & saved ──
class PdfGeneratingDialog extends StatelessWidget {
  const PdfGeneratingDialog({super.key});

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
              const SizedBox(height: 6),
              Text(
                'कृपया प्रतीक्षा करें',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
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
