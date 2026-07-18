import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String _androidAppOpenAdUnitId = 'ca-app-pub-1638673809508848/3074105061';
const Duration _maxAppOpenAdCacheAge = Duration(hours: 4);
const Duration _minimumForegroundInterval = Duration(minutes: 4);
const int _maxSessionAppOpenShows = 2;
const Duration _baseRetryDelay = Duration(seconds: 30);
const Duration _maxRetryDelay = Duration(minutes: 5);

String? get _appOpenAdUnitId {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return _androidAppOpenAdUnitId;
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
      name: 'AppOpenAdManager',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  }());
}

class AppOpenAdManager with WidgetsBindingObserver {
  AppOpenAdManager._()
    : navigatorObserver = _AppOpenNavigatorObserver(),
      navigatorKey = GlobalKey<NavigatorState>() {
    (navigatorObserver as _AppOpenNavigatorObserver)._manager = this;
  }

  static final AppOpenAdManager instance = AppOpenAdManager._();

  final GlobalKey<NavigatorState> navigatorKey;
  final NavigatorObserver navigatorObserver;

  AppOpenAd? _appOpenAd;
  DateTime? _loadedAt;
  DateTime? _lastShownAt;
  Timer? _retryTimer;
  Timer? _expirationTimer;

  bool _initialized = false;
  bool _initializing = false;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _isDisposed = false;
  bool _appIsResumed = true;
  bool _homeTabVisible = true;
  bool _coldStartShowPending = true;
  bool _coldStartHomeLeft = false;
  int _failedLoadCount = 0;
  int _loadRequestToken = 0;
  int _foregroundEventId = 0;
  int _lastShownForegroundEventId = -1;
  int _sessionShowCount = 0;
  bool _foregroundShowUsed = false;

  bool get _isSupported => _appOpenAdUnitId != null;

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

  void setHomeTabVisible(bool isVisible) {
    _homeTabVisible = isVisible;
    if (!isVisible && _coldStartShowPending && !_isShowing) {
      _coldStartHomeLeft = true;
    }
    _maybeShowColdStartAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _appIsResumed = true;
        _foregroundEventId++;
        _showOnForegroundIfAvailable();
        _loadOne();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _appIsResumed = false;
        break;
      case AppLifecycleState.detached:
        dispose();
        break;
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _retryTimer = null;
    _destroyLoadedAd();
  }

  void _handleRoutePushed(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && _coldStartShowPending && !_isShowing) {
      _coldStartHomeLeft = true;
    }
  }

  void _handleRouteReplaced({
    Route<dynamic>? newRoute,
    Route<dynamic>? oldRoute,
  }) {
    if (oldRoute != null && _coldStartShowPending && !_isShowing) {
      _coldStartHomeLeft = true;
    }
  }

  void _maybeShowColdStartAd() {
    if (!_coldStartShowPending || _isShowing || _appOpenAd == null) return;

    if (_coldStartHomeLeft) {
      _coldStartShowPending = false;
      return;
    }

    if (!_isColdStartHomeVisible) return;

    _coldStartShowPending = false;
    _showLoadedAd(ignoreMinimumInterval: true);
  }

  bool get _isColdStartHomeVisible {
    if (!_appIsResumed || !_homeTabVisible) return false;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return false;
    return !navigator.canPop();
  }

  void _showOnForegroundIfAvailable() {
    if (_foregroundShowUsed || !_canShowInCurrentSession) return;
    if (_lastShownForegroundEventId == _foregroundEventId) return;
    if (_appOpenAd == null) {
      _loadOne();
      return;
    }
    if (!_canShowForMinimumInterval) return;
    _showLoadedAd(isForegroundEvent: true);
  }

  bool get _canShowInCurrentSession =>
      _sessionShowCount < _maxSessionAppOpenShows;

  bool get _canShowForMinimumInterval {
    final lastShownAt = _lastShownAt;
    return lastShownAt == null ||
        DateTime.now().difference(lastShownAt) >= _minimumForegroundInterval;
  }

  bool get _isLoadedAdExpired {
    final loadedAt = _loadedAt;
    return loadedAt != null &&
        DateTime.now().difference(loadedAt) >= _maxAppOpenAdCacheAge;
  }

  void _loadOne() {
    if (_isDisposed ||
        !_initialized ||
        _isLoading ||
        _isShowing ||
        !_canShowInCurrentSession ||
        _foregroundShowUsed) {
      return;
    }
    if (_appOpenAd != null) {
      if (_isLoadedAdExpired) {
        _destroyLoadedAd();
      } else {
        return;
      }
    }

    final adUnitId = _appOpenAdUnitId;
    if (adUnitId == null) return;

    _isLoading = true;
    final requestToken = ++_loadRequestToken;

    unawaited(
      AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            if (_isDisposed ||
                requestToken != _loadRequestToken ||
                _isShowing) {
              ad.dispose();
              return;
            }

            _isLoading = false;
            _failedLoadCount = 0;
            _retryTimer?.cancel();
            _retryTimer = null;
            _setLoadedAd(ad);
            _log('App Open loaded.');
            _maybeShowColdStartAd();
          },
          onAdFailedToLoad: (error) {
            if (_isDisposed || requestToken != _loadRequestToken) return;
            _isLoading = false;
            _appOpenAd = null;
            _loadedAt = null;
            _scheduleRetry(error);
          },
        ),
      ),
    );
  }

  void _setLoadedAd(AppOpenAd ad) {
    _destroyLoadedAd();
    _appOpenAd = ad;
    _loadedAt = DateTime.now();
    _scheduleExpirationRefresh();
  }

  void _showLoadedAd({
    bool ignoreMinimumInterval = false,
    bool isForegroundEvent = false,
  }) {
    if (_isDisposed || !_initialized || _isShowing) return;
    if (!_canShowInCurrentSession ||
        (isForegroundEvent && _foregroundShowUsed)) {
      return;
    }
    if (!ignoreMinimumInterval && !_canShowForMinimumInterval) return;

    if (_isLoadedAdExpired) {
      _destroyLoadedAd();
      _loadOne();
      return;
    }

    final ad = _appOpenAd;
    if (ad == null) {
      _loadOne();
      return;
    }

    _appOpenAd = null;
    _loadedAt = null;
    _expirationTimer?.cancel();
    _expirationTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _isShowing = true;
    _lastShownAt = DateTime.now();
    _lastShownForegroundEventId = _foregroundEventId;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _recordShown(isForegroundEvent: isForegroundEvent);
        _log('App Open shown.');
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        _finishShowingAd(dismissedAd);
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        _log('App Open failed to show.', error);
        _finishShowingAd(failedAd);
      },
    );

    try {
      unawaited(ad.show());
    } catch (error, stackTrace) {
      _log('App Open show threw.', error, stackTrace);
      _finishShowingAd(ad);
    }
  }

  void _recordShown({required bool isForegroundEvent}) {
    _sessionShowCount++;
    if (isForegroundEvent) {
      _foregroundShowUsed = true;
    }
  }

  void _scheduleExpirationRefresh() {
    _expirationTimer?.cancel();
    _expirationTimer = Timer(_maxAppOpenAdCacheAge, () {
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
    _log('App Open load failed. Retrying later.', error);

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

  void _finishShowingAd(AppOpenAd ad) {
    try {
      ad.fullScreenContentCallback = null;
      ad.dispose();
    } catch (error, stackTrace) {
      _log('App Open dispose after show failed.', error, stackTrace);
    }

    _isShowing = false;
    if (!_isDisposed) {
      _loadOne();
    }
  }

  void _destroyLoadedAd() {
    _expirationTimer?.cancel();
    _expirationTimer = null;

    final ad = _appOpenAd;
    _appOpenAd = null;
    _loadedAt = null;

    if (ad == null) return;
    try {
      ad.fullScreenContentCallback = null;
      ad.dispose();
    } catch (error, stackTrace) {
      _log('App Open dispose failed.', error, stackTrace);
    }
  }
}

class _AppOpenNavigatorObserver extends NavigatorObserver {
  AppOpenAdManager? _manager;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _manager?._handleRoutePushed(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _manager?._handleRouteReplaced(newRoute: newRoute, oldRoute: oldRoute);
  }
}
