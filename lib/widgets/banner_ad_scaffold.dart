import 'package:flutter/material.dart';

import '../ads/shared_banner_ad.dart';

class BannerAdScaffold extends StatelessWidget {
  const BannerAdScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.protectBottomInset = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool protectBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Column(
        children: [
          Expanded(child: body),
          SharedBannerAd(protectBottomInset: protectBottomInset),
        ],
      ),
    );
  }
}
