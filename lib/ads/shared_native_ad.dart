import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String _androidNativeAdUnitId = 'ca-app-pub-1638673809508848/3504661542';
const String _androidNativeTestAdUnitId =
    'ca-app-pub-3940256099942544/2247696110';
const String _androidNativeAdFactoryId = 'sharedNativeAdFactory';
const double _nativeAdMinHeight = 360;
const double _nativeAdMaxHeight = 420;
const Duration _baseRetryDelay = Duration(seconds: 30);
const Duration _maxRetryDelay = Duration(minutes: 5);

String? get _nativeAdUnitId {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return kDebugMode ? _androidNativeTestAdUnitId : _androidNativeAdUnitId;
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

  static void preload({required String placementId}) {
    _NativeAdCache.instance.slotFor(placementId).preload();
  }

  @override
  State<SharedNativeAd> createState() => _SharedNativeAdState();
}

class _SharedNativeAdState extends State<SharedNativeAd> {
  late _NativeAdSlot _slot;
  late VoidCallback _slotListener;

  @override
  void initState() {
    super.initState();
    _slotListener = () {
      if (mounted) setState(() {});
    };
    _attachSlot();
  }

  @override
  void didUpdateWidget(covariant SharedNativeAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placementId != widget.placementId) {
      _slot.removeListener(_slotListener);
      _attachSlot();
    }
  }

  @override
  void dispose() {
    _slot.removeListener(_slotListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nativeAd = _slot.loadedAd;
    if (nativeAd == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return SizedBox(
          height: _heightForWidth(context, width),
          width: double.infinity,
          child: AdWidget(ad: nativeAd),
        );
      },
    );
  }

  void _attachSlot() {
    _slot = _NativeAdCache.instance.slotFor(widget.placementId);
    _slot.addListener(_slotListener);
    _slot.preload();
  }

  double _heightForWidth(BuildContext context, double width) {
    final safeWidth = width.isFinite && width > 0
        ? width
        : MediaQuery.sizeOf(context).width;
    return (safeWidth * 0.96).clamp(_nativeAdMinHeight, _nativeAdMaxHeight);
  }
}

class _NativeAdCache {
  _NativeAdCache._();

  static final _NativeAdCache instance = _NativeAdCache._();

  final Map<String, _NativeAdSlot> _slots = {};

  _NativeAdSlot slotFor(String placementId) {
    return _slots.putIfAbsent(placementId, () => _NativeAdSlot(placementId));
  }
}

class _NativeAdSlot {
  _NativeAdSlot(this.placementId);

  final String placementId;
  final Set<VoidCallback> _listeners = {};

  NativeAd? _loadedAd;
  NativeAd? _loadingAd;
  Timer? _retryTimer;
  bool _isLoading = false;
  int _failedLoadCount = 0;
  int _loadRequestToken = 0;

  NativeAd? get loadedAd => _loadedAd;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void preload() {
    if (_loadedAd != null || _loadingAd != null || _isLoading) return;
    _loadOne();
  }

  void _loadOne() {
    final adUnitId = _nativeAdUnitId;
    if (adUnitId == null ||
        _loadedAd != null ||
        _loadingAd != null ||
        _isLoading) {
      return;
    }

    _isLoading = true;
    final requestToken = ++_loadRequestToken;

    unawaited(_loadAfterMobileAdsInit(adUnitId, requestToken));
  }

  Future<void> _loadAfterMobileAdsInit(
    String adUnitId,
    int requestToken,
  ) async {
    try {
      await MobileAds.instance.initialize();
    } catch (error, stackTrace) {
      if (requestToken != _loadRequestToken) return;
      _isLoading = false;
      _scheduleRetry(error, stackTrace);
      return;
    }

    if (requestToken != _loadRequestToken || _loadedAd != null) {
      _isLoading = false;
      return;
    }

    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: _androidNativeAdFactoryId,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.any,
        videoOptions: VideoOptions(startMuted: true),
      ),
      customOptions: {'placementId': placementId},
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (requestToken != _loadRequestToken) {
            ad.dispose();
            return;
          }

          _loadingAd = null;
          _loadedAd = ad as NativeAd;
          _isLoading = false;
          _failedLoadCount = 0;
          _retryTimer?.cancel();
          _retryTimer = null;
          _notifyListeners();
          _log('Native ad loaded for $placementId.');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (requestToken != _loadRequestToken) return;

          _loadingAd = null;
          _isLoading = false;
          _notifyListeners();
          _scheduleRetry(error);
        },
      ),
    );

    _loadingAd = nativeAd;
    unawaited(nativeAd.load());
  }

  void _scheduleRetry(Object error, [StackTrace? stackTrace]) {
    _failedLoadCount++;
    final delay = _retryDelayForAttempt(_failedLoadCount);
    _log(
      'Native ad failed for $placementId. Retrying later.',
      error,
      stackTrace,
    );

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      _loadOne();
    });
  }

  Duration _retryDelayForAttempt(int attempt) {
    var seconds = _baseRetryDelay.inSeconds;
    for (var i = 1; i < attempt; i++) {
      seconds *= 2;
      if (seconds >= _maxRetryDelay.inSeconds) {
        return _maxRetryDelay;
      }
    }
    return Duration(seconds: seconds);
  }

  void _notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }
}
