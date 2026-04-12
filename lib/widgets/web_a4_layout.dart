import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A4 paper width in logical pixels at 96 dpi (210 mm ≈ 794 px).
const double _kA4Width = 794.0;

/// Width of each side ad column.
const double _kAdColumnWidth = 160.0;

/// Minimum total width required to show A4 + side ads.
/// A4(794) + 2×ads(160) + breathing room ≈ 1140.
const double _kMinDesktopWidth = 1140.0;

/// On **desktop web** (≥1140px): A4-centred column + side ad placeholders.
/// On **mobile/tablet web** or **native**: returns [child] unchanged.
class WebA4Layout extends StatelessWidget {
  final Widget child;

  const WebA4Layout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || MediaQuery.sizeOf(context).width < _kMinDesktopWidth) {
      return child;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _kAdColumnWidth,
          child: const _AdBannerPlaceholder(side: 'left'),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kA4Width),
              child: child,
            ),
          ),
        ),
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
