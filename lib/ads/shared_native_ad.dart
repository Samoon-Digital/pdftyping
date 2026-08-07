import 'package:flutter/widgets.dart';

import 'ad_feature_flags.dart';

class SharedNativeAd extends StatelessWidget {
  const SharedNativeAd({super.key, required this.placementId});

  final String placementId;

  static void preload({required String placementId}) {
    if (!nativeAdsEnabled) return;
  }

  @override
  Widget build(BuildContext context) {
    if (!nativeAdsEnabled) return const SizedBox.shrink();
    return const SizedBox.shrink();
  }
}
