import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/native_ad_manager.dart';

class SharedNativeAdSlot extends StatefulWidget {
  const SharedNativeAdSlot({
    super.key,
    this.height = 300,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  final double height;
  final EdgeInsetsGeometry margin;

  @override
  State<SharedNativeAdSlot> createState() => _SharedNativeAdSlotState();
}

class _SharedNativeAdSlotState extends State<SharedNativeAdSlot> {
  final NativeAdManager _manager = NativeAdManager.instance;
  NativeAd? _ad;
  ScrollPosition? _scrollPosition;
  bool _isVisible = false;
  bool _entryHandled = false;
  bool _checkScheduled = false;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_handleManagerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == _scrollPosition) return;
    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _scrollPosition = position;
    _scrollPosition?.addListener(_scheduleVisibilityCheck);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _manager.removeListener(_handleManagerChanged);
    final ad = _ad;
    if (ad != null) {
      _manager.releaseMountedAd(ad);
    }
    super.dispose();
  }

  void _scheduleVisibilityCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (mounted) _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final visible = bottom > 0 && top < viewportHeight;

    if (visible == _isVisible) return;
    _isVisible = visible;

    if (_isVisible) {
      _handleViewportEntry();
    } else {
      _handleViewportExit();
    }
  }

  void _handleViewportEntry() {
    if (_entryHandled) return;
    _entryHandled = true;

    _manager.start();
    _attachReadyAdOrRequest();
  }

  void _handleViewportExit() {
    _entryHandled = false;
    final ad = _ad;
    if (ad == null) return;
    setState(() => _ad = null);
    _manager.releaseMountedAd(ad);
  }

  void _handleManagerChanged() {
    if (!mounted || !_isVisible || _ad != null) return;
    _attachReadyAdOrRequest();
  }

  void _attachReadyAdOrRequest() {
    final readyAd = _manager.takeReadyAd();
    if (readyAd != null) {
      setState(() => _ad = readyAd);
      return;
    }
    _manager.requestFreshAd();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: widget.height,
        margin: widget.margin,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7E0D6)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _ad == null
              ? const SizedBox.expand(key: ValueKey('native-ad-placeholder'))
              : AdWidget(key: ValueKey(_ad), ad: _ad!),
        ),
      ),
    );
  }
}
