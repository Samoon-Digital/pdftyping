import 'package:flutter/material.dart';

import '../services/ad_service.dart';

class ScreenEntryInterstitialHost extends StatefulWidget {
  const ScreenEntryInterstitialHost({
    super.key,
    required this.child,
    this.placement,
  });

  final Widget child;
  final ScreenInterstitialPlacement? placement;

  @override
  State<ScreenEntryInterstitialHost> createState() =>
      _ScreenEntryInterstitialHostState();
}

class _ScreenEntryInterstitialHostState
    extends State<ScreenEntryInterstitialHost> {
  @override
  void initState() {
    super.initState();
    final placement = widget.placement;
    if (placement == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AdService.instance.loadAndShowScreenInterstitial(
        placement: placement,
        canShow: () => mounted && (ModalRoute.of(context)?.isCurrent ?? true),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
