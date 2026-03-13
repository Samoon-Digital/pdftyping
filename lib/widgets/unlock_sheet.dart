import 'package:flutter/material.dart';
import '../services/ad_service.dart';

/// Shows a bottom sheet with two unlock options:
///  1. Watch a reward ad (free unlock)
///  2. Premium (coming soon — disabled for now)
///
/// Returns `true` if the template was successfully unlocked, `false` otherwise.
Future<bool> showUnlockSheet({
  required BuildContext context,
  required String templateId,
  required String templateTitle,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _UnlockSheet(templateId: templateId, templateTitle: templateTitle),
  );
  return result ?? false;
}

class _UnlockSheet extends StatefulWidget {
  final String templateId;
  final String templateTitle;

  const _UnlockSheet({required this.templateId, required this.templateTitle});

  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  bool _loading = false;

  void _watchAd() {
    setState(() => _loading = true);

    AdService.instance.showRewardAd(
      templateId: widget.templateId,
      onRewarded: () {
        if (mounted) Navigator.of(context).pop(true);
      },
      onAdNotReady: () {
        setState(() => _loading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'विज्ञापन लोड हो रहा है, कृपया कुछ सेकंड बाद फिर कोशिश करें।',
              style: TextStyle(fontFamily: 'NotoSansDevanagari'),
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Lock icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_rounded, size: 36, color: primary),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'इस आवेदन को अनलॉक करें',
            style: TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),

          // Template name
          Text(
            widget.templateTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontSize: 14,
              color: Color(0xFF757575),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // ── Option 1: Watch Ad ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _watchAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_circle_filled_rounded),
              label: Text(
                _loading ? 'लोड हो रहा है...' : 'विज्ञापन देखकर अनलॉक करें',
                style: const TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Option 2: Premium (disabled for now) ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: null, // Will enable when premium is added
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'प्रीमियम से अनलॉक करें',
                    style: TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  _ComingSoonBadge(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        'जल्द',
        style: TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.orange.shade800,
        ),
      ),
    );
  }
}
