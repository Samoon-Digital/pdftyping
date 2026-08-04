import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_open_ad_manager.dart';

const String _androidInterstitialAdUnitId =
    'ca-app-pub-1638673809508848/1848500378';
const String _androidInterstitialTestAdUnitId =
    'ca-app-pub-3940256099942544/1033173712';
const Duration _maxInterstitialCacheAge = Duration(hours: 1);
const Duration _baseRetryDelay = Duration(seconds: 30);
const Duration _maxRetryDelay = Duration(minutes: 5);
const Duration _preShowNoticeDuration = Duration(milliseconds: 1200);
const Duration _pendingShowTimeout = Duration(seconds: 10);

String? get _interstitialAdUnitId {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return kDebugMode
          ? _androidInterstitialTestAdUnitId
          : _androidInterstitialAdUnitId;
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
  Timer? _pendingShowTimer;
  OverlayEntry? _noticeOverlayEntry;

  bool _initialized = false;
  bool _initializing = false;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _showPending = false;
  bool _pendingShowRequest = false;
  bool _appIsForeground = true;
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
      _scheduleRetry(error);
    } finally {
      _initializing = false;
    }
  }

  /// Shows the currently loaded interstitial after a short top notice.
  ///
  /// If the screen asks before preload finishes, the request is kept briefly;
  /// once the ad loads, the notice is shown and then the ad opens.
  void showIfAvailable() {
    if (!_isSupported || _isDisposed) return;
    if (!_initialized) {
      _queuePendingShow();
      unawaited(initialize());
      return;
    }
    if (_isShowing || _showPending || !_appIsForeground) return;

    if (_isLoadedAdExpired) {
      _destroyLoadedAd();
      _queuePendingShow();
      _loadOne();
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _queuePendingShow();
      _loadOne();
      return;
    }

    _beginShowWithNotice(ad);
  }

  /// Releases all manager-owned timers, listeners, and loaded ad references.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _retryTimer = null;
    _pendingShowTimer?.cancel();
    _pendingShowTimer = null;
    _removeNoticeOverlay();
    _destroyLoadedAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _appIsForeground = true;
        _performMaintenance();
        _maybeUsePendingShow();
        break;
      case AppLifecycleState.detached:
        dispose();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _appIsForeground = false;
        _clearPendingShow();
        break;
    }
  }

  void _performMaintenance() {
    if (_isDisposed || !_initialized || _isShowing || _showPending) return;
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
    if (_isDisposed ||
        !_initialized ||
        _isLoading ||
        _isShowing ||
        _showPending) {
      return;
    }
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
          if (_isDisposed ||
              requestToken != _loadRequestToken ||
              _isShowing ||
              _showPending) {
            ad.dispose();
            return;
          }

          _isLoading = false;
          _failedLoadCount = 0;
          _retryTimer?.cancel();
          _retryTimer = null;
          _setLoadedAd(ad);
          _log('Interstitial loaded.');
          _maybeUsePendingShow();
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
      if (_isDisposed || _isShowing || _showPending) return;
      if (_isLoadedAdExpired) {
        _destroyLoadedAd();
      }
      _loadOne();
    });
  }

  void _queuePendingShow() {
    if (_isDisposed || !_appIsForeground) return;
    _pendingShowRequest = true;
    _pendingShowTimer?.cancel();
    _pendingShowTimer = Timer(_pendingShowTimeout, _clearPendingShow);
  }

  void _clearPendingShow() {
    _pendingShowRequest = false;
    _pendingShowTimer?.cancel();
    _pendingShowTimer = null;
  }

  void _maybeUsePendingShow() {
    if (!_pendingShowRequest || _isDisposed || !_appIsForeground) return;
    if (_isShowing || _showPending || _isLoadedAdExpired) return;

    final ad = _interstitialAd;
    if (ad == null) return;

    _clearPendingShow();
    _beginShowWithNotice(ad);
  }

  void _beginShowWithNotice(InterstitialAd ad) {
    _showPending = true;
    unawaited(_showAfterNotice(ad));
  }

  void _scheduleRetry([Object? error]) {
    if (_isDisposed || _isShowing || _showPending || !_isSupported) return;

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

  Future<void> _showAfterNotice(InterstitialAd ad) async {
    var shouldLoadAfterPending = false;
    try {
      await _showTopAdNotice();
      if (_isDisposed || !_appIsForeground || !identical(_interstitialAd, ad)) {
        return;
      }
      if (_isLoadedAdExpired) {
        _destroyLoadedAd();
        shouldLoadAfterPending = true;
        return;
      }
      _showLoadedAd(ad);
    } finally {
      if (!_isShowing) {
        _showPending = false;
        if (shouldLoadAfterPending && !_isDisposed) {
          _loadOne();
        }
      }
    }
  }

  Future<void> _showTopAdNotice() async {
    final overlay =
        AppOpenAdManager.instance.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      await Future<void>.delayed(_preShowNoticeDuration);
      return;
    }

    _removeNoticeOverlay();
    _noticeOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.paddingOf(context).top + 10,
          left: 14,
          right: 14,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    'Ad will appear shortly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_noticeOverlayEntry!);
    try {
      await Future<void>.delayed(_preShowNoticeDuration);
    } finally {
      _removeNoticeOverlay();
    }
  }

  void _removeNoticeOverlay() {
    _noticeOverlayEntry?.remove();
    _noticeOverlayEntry = null;
  }

  void _showLoadedAd(InterstitialAd ad) {
    _interstitialAd = null;
    _loadedAt = null;
    _expirationTimer?.cancel();
    _expirationTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    AppOpenAdManager.instance.suppressNextForegroundShow();
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
      unawaited(ad.show());
    } catch (error, stackTrace) {
      _log('Interstitial show threw.', error, stackTrace);
      _finishShowingAd(ad);
    }
  }

  void _finishShowingAd(InterstitialAd ad) {
    try {
      ad.fullScreenContentCallback = null;
      ad.dispose();
    } catch (error, stackTrace) {
      _log('Interstitial dispose after show failed.', error, stackTrace);
    }

    _isShowing = false;
    _showPending = false;
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
