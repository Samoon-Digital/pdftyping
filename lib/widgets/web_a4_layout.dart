import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A4 paper width in logical pixels at 96 dpi (210 mm ≈ 794 px).
const double _kA4Width = 794.0;

/// Width of each side ad column — reserve space for future banner ads.
const double _kAdColumnWidth = 160.0;

/// On **web**: wraps [child] in a centred A4-wide column with sticky
/// ad-banner placeholder columns on both sides.
/// On **mobile/desktop**: returns [child] completely unchanged.
class WebA4Layout extends StatelessWidget {
  final Widget child;

  const WebA4Layout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left ad column ──────────────────────────────────────────────
        SizedBox(
          width: _kAdColumnWidth,
          child: const _AdBannerPlaceholder(side: 'left'),
        ),

        // ── A4-constrained main content ──────────────────────────────────
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kA4Width),
              child: child,
            ),
          ),
        ),

        // ── Right ad column ─────────────────────────────────────────────
        SizedBox(
          width: _kAdColumnWidth,
          child: const _AdBannerPlaceholder(side: 'right'),
        ),
      ],
    );
  }
}

/// Sticky placeholder shown until real ad widgets are plugged in.
/// Replace the contents of [build] with your AdSense / reward-ad widget.
class _AdBannerPlaceholder extends StatelessWidget {
  final String side;
  const _AdBannerPlaceholder({required this.side});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 600,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ad_units_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Ad Banner',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '150 × 600',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            side,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}
