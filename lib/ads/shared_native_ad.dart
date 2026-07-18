import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String _androidNativeAdUnitId = 'ca-app-pub-1638673809508848/3504661542';
const String _androidNativeAdFactoryId = 'sharedNativeAdFactory';
const double _nativeAdMinHeight = 360;
const double _nativeAdMaxHeight = 420;

String? get _nativeAdUnitId {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return _androidNativeAdUnitId;
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return null;
  }
}

void _log(String message, [Object? error, StackTrace? stackTrace]) {
  assert(() {
    developer.log(
      message,
      name: 'SharedNativeAd',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  }());
}

class SharedNativeAd extends StatefulWidget {
  final String placementId;

  const SharedNativeAd({super.key, required this.placementId});

  @override
  State<SharedNativeAd> createState() => _SharedNativeAdState();
}

class _SharedNativeAdState extends State<SharedNativeAd> {
  final _visibilityKey = GlobalKey();

  NativeAd? _nativeAd;
  ScrollPosition? _scrollPosition;
  Timer? _visibilityTimer;
  bool _loadStarted = false;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachAndCheck());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachAndCheck());
  }

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFailed) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      key: _visibilityKey,
      builder: (context, constraints) {
        if (!_isLoaded || _nativeAd == null) {
          return const SizedBox.shrink();
        }

        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return SizedBox(
          height: _heightForWidth(width),
          width: double.infinity,
          child: AdWidget(ad: _nativeAd!),
        );
      },
    );
  }

  void _attachAndCheck() {
    if (!mounted || _loadStarted || _isFailed) return;
    _attachScrollListener();
    _scheduleVisibilityCheck();
  }

  void _attachScrollListener() {
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _scrollPosition)) return;

    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _scrollPosition = position;
    _scrollPosition?.addListener(_scheduleVisibilityCheck);
  }

  void _scheduleVisibilityCheck() {
    if (_loadStarted || _visibilityTimer?.isActive == true) return;
    _visibilityTimer = Timer(const Duration(milliseconds: 80), () {
      _visibilityTimer = null;
      _checkVisibilityAndLoad();
    });
  }

  void _checkVisibilityAndLoad() {
    if (!mounted || _loadStarted || _isFailed) return;
    if (_isVisibleInViewport()) {
      _loadNativeAd();
    }
  }

  bool _isVisibleInViewport() {
    final context = _visibilityKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (context == null ||
        renderObject is! RenderBox ||
        !renderObject.hasSize) {
      return false;
    }

    final position = _scrollPosition;
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (position != null && viewport != null && position.hasViewportDimension) {
      final markerOffset = viewport.getOffsetToReveal(renderObject, 0).offset;
      final visibleStart = position.pixels;
      final visibleEnd = position.pixels + position.viewportDimension;
      return markerOffset >= visibleStart && markerOffset <= visibleEnd;
    }

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;
    return topLeft.dy >= 0 && topLeft.dy <= screenHeight;
  }

  double _heightForWidth(double width) {
    final safeWidth = width.isFinite && width > 0
        ? width
        : MediaQuery.sizeOf(context).width;
    return (safeWidth * 0.96).clamp(_nativeAdMinHeight, _nativeAdMaxHeight);
  }

  void _loadNativeAd() {
    final adUnitId = _nativeAdUnitId;
    if (adUnitId == null) {
      _isFailed = true;
      return;
    }

    _loadStarted = true;
    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: _androidNativeAdFactoryId,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.any,
        videoOptions: VideoOptions(startMuted: true),
      ),
      customOptions: {'placementId': widget.placementId},
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _nativeAd = ad as NativeAd;
            _isLoaded = true;
          });
          _log('Native ad loaded for ${widget.placementId}.');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _log('Native ad failed for ${widget.placementId}.', error);
          if (!mounted) return;
          setState(() {
            _nativeAd = null;
            _isLoaded = false;
            _isFailed = true;
          });
        },
      ),
    );

    _nativeAd = nativeAd;
    unawaited(nativeAd.load());
  }
}
