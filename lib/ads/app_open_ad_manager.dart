import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'interstitial_manager.dart';

const String _androidAppOpenAdUnitId = 'ca-app-pub-1638673809508848/3074105061';
const String _androidAppOpenTestAdUnitId =
    'ca-app-pub-3940256099942544/9257395921';
const int _maxAppOpenAdsPerSession = 2;
const Duration _maxAppOpenCacheAge = Duration(hours: 4);

String? get _appOpenAdUnitId {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return kDebugMode ? _androidAppOpenTestAdUnitId : _androidAppOpenAdUnitId;
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

class AppOpenAdManager extends NavigatorObserver with WidgetsBindingObserver {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  DateTime? _loadedAt;
  bool _started = false;
  bool _isLoading = false;
  bool _isShowingAd = false;
  bool _wasInBackground = false;
  int _shownCount = 0;
  int _pageRouteDepth = 0;
  int _loadRequestToken = 0;

  bool get isUserOnHomePage => _pageRouteDepth <= 1;

  void start() {
    if (_started || _appOpenAdUnitId == null) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeAndLoad());
  }

  Future<void> _initializeAndLoad() async {
    try {
      await MobileAds.instance.initialize();
      _loadAd();
    } catch (error, stackTrace) {
      _log('Mobile Ads initialization failed.', error, stackTrace);
    }
  }

  void _loadAd() {
    if (_shownCount >= _maxAppOpenAdsPerSession ||
        _isLoading ||
        _appOpenAd != null) {
      return;
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
            if (requestToken != _loadRequestToken ||
                _shownCount >= _maxAppOpenAdsPerSession) {
              ad.dispose();
              return;
            }

            _isLoading = false;
            _appOpenAd = ad;
            _loadedAt = DateTime.now();

            if (_shownCount == 0) {
              _showIfAvailable(requireHomePage: true);
            }
          },
          onAdFailedToLoad: (error) {
            if (requestToken != _loadRequestToken) return;
            _isLoading = false;
            _log('App open ad failed to load.', error);
          },
        ),
      ).catchError((Object error, StackTrace stackTrace) {
        if (requestToken != _loadRequestToken) return;
        _isLoading = false;
        _log('App open ad load threw.', error, stackTrace);
      }),
    );
  }

  void _showIfAvailable({required bool requireHomePage}) {
    if (_isShowingAd || _shownCount >= _maxAppOpenAdsPerSession) return;
    if (InterstitialManager.instance.isShowingFullScreenAd) return;

    if (_isCachedAdExpired) {
      _disposeCachedAd();
      _loadAd();
      return;
    }

    final ad = _appOpenAd;
    if (ad == null) {
      _loadAd();
      return;
    }

    if (requireHomePage && !isUserOnHomePage) return;

    _appOpenAd = null;
    _loadedAt = null;
    _isShowingAd = true;

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (_) {
        _shownCount++;
      },
      onAdDismissedFullScreenContent: _finishShowingAd,
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        _log('App open ad failed to show.', error);
        _finishShowingAd(failedAd);
      },
    );

    try {
      unawaited(ad.show());
    } catch (error, stackTrace) {
      _log('App open ad show threw.', error, stackTrace);
      _finishShowingAd(ad);
    }
  }

  bool get _isCachedAdExpired {
    final loadedAt = _loadedAt;
    return loadedAt != null &&
        DateTime.now().difference(loadedAt) >= _maxAppOpenCacheAge;
  }

  void _finishShowingAd(AppOpenAd ad) {
    try {
      ad.fullScreenContentCallback = null;
      ad.dispose();
    } catch (error, stackTrace) {
      _log('App open ad dispose failed.', error, stackTrace);
    }

    _isShowingAd = false;
    if (_shownCount < _maxAppOpenAdsPerSession) {
      _loadAd();
    }
  }

  void _disposeCachedAd() {
    final ad = _appOpenAd;
    _appOpenAd = null;
    _loadedAt = null;
    if (ad == null) return;
    try {
      ad.dispose();
    } catch (error, stackTrace) {
      _log('Cached app open ad dispose failed.', error, stackTrace);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_wasInBackground) return;
        _wasInBackground = false;
        _showIfAvailable(requireHomePage: false);
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (!_isShowingAd) {
          _wasInBackground = true;
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic>) {
      _pageRouteDepth++;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic> && _pageRouteDepth > 0) {
      _pageRouteDepth--;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic> && _pageRouteDepth > 0) {
      _pageRouteDepth--;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute is PageRoute<dynamic> && newRoute is! PageRoute<dynamic>) {
      _pageRouteDepth = (_pageRouteDepth - 1).clamp(0, 1 << 20);
    } else if (oldRoute is! PageRoute<dynamic> &&
        newRoute is PageRoute<dynamic>) {
      _pageRouteDepth++;
    }
  }
}
