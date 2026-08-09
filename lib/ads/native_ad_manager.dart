import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, TargetPlatform, defaultTargetPlatform, kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String nativeAdFactoryId = 'sharedNativeAdFactory';
const String _androidNativeAdUnitId = 'ca-app-pub-1638673809508848/3504661542';
const String _androidNativeTestAdUnitId =
    'ca-app-pub-3940256099942544/2247696110';

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
      name: 'NativeAdManager',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  }());
}

class NativeAdManager extends ChangeNotifier {
  NativeAdManager._();

  static final NativeAdManager instance = NativeAdManager._();

  NativeAd? _nativeAd;
  bool _started = false;
  bool _isLoading = false;
  bool _isReady = false;
  bool _isMounted = false;
  bool _isDisposed = false;
  int _loadToken = 0;

  bool get isReady => _isReady && !_isMounted && _nativeAd != null;

  void start() {
    if (_started || _nativeAdUnitId == null || _isDisposed) return;
    _started = true;
    unawaited(_initializeAndLoad());
  }

  Future<void> _initializeAndLoad() async {
    try {
      await MobileAds.instance.initialize();
      requestFreshAd();
    } catch (error, stackTrace) {
      _log('Native ads initialization failed.', error, stackTrace);
    }
  }

  void requestFreshAd() {
    if (_isDisposed || _isLoading || _isMounted || _nativeAd != null) return;

    final adUnitId = _nativeAdUnitId;
    if (adUnitId == null) return;

    _isLoading = true;
    _isReady = false;
    final token = ++_loadToken;

    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: nativeAdFactoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          if (_isDisposed || token != _loadToken) {
            loadedAd.dispose();
            return;
          }
          _isLoading = false;
          _nativeAd = loadedAd as NativeAd;
          _isReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (failedAd, error) {
          if (token != _loadToken) return;
          failedAd.dispose();
          _isLoading = false;
          _isReady = false;
          _nativeAd = null;
          _log('Native ad failed to load.', error);
          notifyListeners();
        },
      ),
    );

    unawaited(
      ad.load().catchError((Object error, StackTrace stackTrace) {
        if (token != _loadToken) return;
        ad.dispose();
        _isLoading = false;
        _isReady = false;
        _nativeAd = null;
        _log('Native ad load threw.', error, stackTrace);
        notifyListeners();
      }),
    );
  }

  NativeAd? takeReadyAd() {
    if (!isReady) return null;
    _isMounted = true;
    _isReady = false;
    final ad = _nativeAd;
    _nativeAd = null;
    return ad;
  }

  void releaseMountedAd(NativeAd ad) {
    try {
      ad.dispose();
    } catch (error, stackTrace) {
      _log('Native ad dispose failed.', error, stackTrace);
    }
    _isMounted = false;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }
}
