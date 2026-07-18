import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String _androidInterstitialAdUnitId =
    'ca-app-pub-1638673809508848/1848500378';
const Duration _maxInterstitialCacheAge = Duration(hours: 1);
const Duration _baseRetryDelay = Duration(seconds: 30);
const Duration _maxRetryDelay = Duration(minutes: 5);

String? get _interstitialAdUnitId {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return _androidInterstitialAdUnitId;
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
      name: 'InterstitialManager',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  }());
}

/// Shared production manager for a single preloaded interstitial ad.
///
/// The manager owns loading, retry, expiration, showing, and disposal. Screens
/// should only call [showIfAvailable] at final destination points; navigation
/// decisions stay outside this class.
class InterstitialManager with WidgetsBindingObserver {
  InterstitialManager._();

  static final InterstitialManager instance = InterstitialManager._();

  InterstitialAd? _interstitialAd;
  DateTime? _loadedAt;
  Timer? _retryTimer;
  Timer? _expirationTimer;

  bool _initialized = false;
  bool _initializing = false;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _isDisposed = false;
  int _failedLoadCount = 0;
  int _loadRequestToken = 0;

  bool get _isSupported => _interstitialAdUnitId != null;

  /// Initializes Google Mobile Ads and starts one background preload.
  ///
  /// This method is safe to call more than once. It never blocks app startup
  /// when invoked with `unawaited` from `main`.
  Future<void> initialize() async {
    if (!_isSupported || _isDisposed || _initialized || _initializing) return;

    _initializing = true;
    try {
      await MobileAds.instance.initialize();
      if (_isDisposed) return;
      _initialized = true;
      WidgetsBinding.instance.addObserver(this);
      _loadOne();
    } catch (error, stackTrace) {
      _log('Initialization failed.', error, stackTrace);
      _scheduleRetry();
    } finally {
      _initializing = false;
    }
  }

  /// Shows the currently loaded interstitial immediately, if it is valid.
  ///
  /// If no valid ad is ready, the app continues normally and a background load
  /// is ensured. This method never waits for a network request.
  void showIfAvailable() {
    if (!_isSupported || _isDisposed) return;
    if (!_initialized) {
      unawaited(initialize());
      return;
    }
    if (_isShowing) return;

    if (_isLoadedAdExpired) {
      _destroyLoadedAd();
      _loadOne();
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _loadOne();
      return;
    }

    _interstitialAd = null;
    _loadedAt = null;
    _expirationTimer?.cancel();
    _expirationTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _isShowing = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _log('Interstitial shown.');
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        _finishShowingAd(dismissedAd);
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        _log('Interstitial failed to show.', error);
        _finishShowingAd(failedAd);
      },
    );

    try {
      ad.show();
    } catch (error, stackTrace) {
      _log('Interstitial show threw.', error, stackTrace);
      _finishShowingAd(ad);
    }
  }

  /// Releases all manager-owned timers, listeners, and loaded ad references.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _retryTimer = null;
    _destroyLoadedAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _performMaintenance();
        break;
      case AppLifecycleState.detached:
        dispose();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        break;
    }
  }

  void _performMaintenance() {
    if (_isDisposed || !_initialized || _isShowing) return;
    if (_isLoadedAdExpired) {
      _destroyLoadedAd();
    }
    _loadOne();
  }

  bool get _isLoadedAdExpired {
    final loadedAt = _loadedAt;
    return loadedAt != null &&
        DateTime.now().difference(loadedAt) >= _maxInterstitialCacheAge;
  }

  void _loadOne() {
    if (_isDisposed || !_initialized || _isLoading || _isShowing) return;
    if (_interstitialAd != null) return;

    final adUnitId = _interstitialAdUnitId;
    if (adUnitId == null) return;

    _isLoading = true;
    final requestToken = ++_loadRequestToken;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_isDisposed || requestToken != _loadRequestToken || _isShowing) {
            ad.dispose();
            return;
          }

          _isLoading = false;
          _failedLoadCount = 0;
          _retryTimer?.cancel();
          _retryTimer = null;
          _setLoadedAd(ad);
          _log('Interstitial loaded.');
        },
        onAdFailedToLoad: (error) {
          if (_isDisposed || requestToken != _loadRequestToken) return;
          _isLoading = false;
          _interstitialAd = null;
          _loadedAt = null;
          _scheduleRetry(error);
        },
      ),
    );
  }

  void _setLoadedAd(InterstitialAd ad) {
    _destroyLoadedAd();
    _interstitialAd = ad;
    _loadedAt = DateTime.now();
    _scheduleExpirationRefresh();
  }

  void _scheduleExpirationRefresh() {
    _expirationTimer?.cancel();
    _expirationTimer = Timer(_maxInterstitialCacheAge, () {
      if (_isDisposed || _isShowing) return;
      if (_isLoadedAdExpired) {
        _destroyLoadedAd();
      }
      _loadOne();
    });
  }

  void _scheduleRetry([Object? error]) {
    if (_isDisposed || _isShowing || !_isSupported) return;

    _failedLoadCount++;
    final delay = _retryDelayForAttempt(_failedLoadCount);
    _log('Interstitial load failed. Retrying later.', error);

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (!_initialized) {
        unawaited(initialize());
      } else {
        _loadOne();
      }
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

  void _finishShowingAd(InterstitialAd ad) {
    try {
      ad.fullScreenContentCallback = null;
      ad.dispose();
    } catch (error, stackTrace) {
      _log('Interstitial dispose after show failed.', error, stackTrace);
    }

    _isShowing = false;
    if (!_isDisposed) {
      _loadOne();
    }
  }

  void _destroyLoadedAd() {
    _expirationTimer?.cancel();
    _expirationTimer = null;

    final ad = _interstitialAd;
    _interstitialAd = null;
    _loadedAt = null;

    if (ad == null) return;
    try {
      ad.fullScreenContentCallback = null;
      ad.dispose();
    } catch (error, stackTrace) {
      _log('Interstitial dispose failed.', error, stackTrace);
    }
  }
}
