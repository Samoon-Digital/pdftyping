import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  static const _appOpenRequestWindow = Duration(seconds: 12);
  static const _minBackgroundForAppOpen = Duration(seconds: 2);
  static const _appOpenMaxAge = Duration(hours: 4);
  static const _interstitialMaxAge = Duration(hours: 1);

  // ── Ad Unit IDs ──
  static const _appOpenAdUnit = 'ca-app-pub-1638673809508848/2471334449';
  static const _interstitialAdUnit = 'ca-app-pub-1638673809508848/4556898771';

  // ── App Open state ──
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadedAt;
  bool _aoLoading = false;
  bool _aoShowing = false;
  bool _skipNextResume = false;
  DateTime? _backgroundedAt;
  DateTime? _pendingAppOpenUntil;
  int _appOpenSuppressionCount = 0;

  // ── Interstitial state ──
  InterstitialAd? _interstitialAd;
  DateTime? _interstitialLoadedAt;
  bool _intLoading = false;

  // ── Session / CPM control ──
  // Max 2 interstitials per session. Post-PDF-save bypasses cooldown (highest CPM moment).
  // Regular nav tap: min 3-min cooldown between shows.
  static const _sessionCap = 2;
  static const _cooldown = Duration(minutes: 3);
  int _sessionShown = 0;
  DateTime? _lastShown;

  // ── Init (call once in main) ──
  static Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(instance);
    instance._requestAppOpen();
    instance._loadAppOpen();
    instance._loadInterstitial();
  }

  bool _isExpired(DateTime? loadedAt, Duration maxAge) =>
      loadedAt == null || DateTime.now().difference(loadedAt) > maxAge;

  // ─────────────────────────────────────────
  // APP OPEN AD
  // ─────────────────────────────────────────

  void _loadAppOpen() {
    if (_aoLoading || _appOpenAd != null) return;
    _aoLoading = true;
    AppOpenAd.load(
      adUnitId: _appOpenAdUnit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          _aoLoading = false;
          _showAppOpenIfAvailable();
        },
        onAdFailedToLoad: (_) {
          _aoLoading = false;
          Future.delayed(const Duration(seconds: 10), _loadAppOpen);
        },
      ),
    );
  }

  bool get _appOpenIsSuppressed => _appOpenSuppressionCount > 0;

  void _requestAppOpen() {
    _pendingAppOpenUntil = DateTime.now().add(_appOpenRequestWindow);
    _showAppOpenIfAvailable();
    _loadAppOpen();
  }

  void _clearPendingAppOpen() {
    _pendingAppOpenUntil = null;
  }

  /// Call when user navigates into any editor/non-home screen.
  /// Prevents a loading ad from popping up mid-editor.
  void onNavigatedAway() => _clearPendingAppOpen();

  void pushAppOpenSuppression() {
    _appOpenSuppressionCount++;
    _clearPendingAppOpen();
  }

  void popAppOpenSuppression() {
    if (_appOpenSuppressionCount == 0) return;
    _appOpenSuppressionCount--;
  }

  void _showAppOpenIfAvailable() {
    final pendingAppOpenUntil = _pendingAppOpenUntil;
    final ad = _appOpenAd;
    if (_aoShowing || ad == null || pendingAppOpenUntil == null) {
      return;
    }

    if (_isExpired(_appOpenLoadedAt, _appOpenMaxAge)) {
      ad.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
      _clearPendingAppOpen();
      _loadAppOpen();
      return;
    }

    if (_appOpenIsSuppressed || pendingAppOpenUntil.isBefore(DateTime.now())) {
      _clearPendingAppOpen();
      return;
    }

    _clearPendingAppOpen();
    _skipNextResume = true;
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _aoShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _aoShowing = false;
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _aoShowing = false;
        _skipNextResume = false;
        _loadAppOpen();
      },
    );
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
        _loadAppOpen();
        _loadInterstitial();
        break;
      case AppLifecycleState.resumed:
        if (_skipNextResume) {
          _skipNextResume = false;
          return;
        }
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt == null) return;
        if (DateTime.now().difference(backgroundedAt) <
            _minBackgroundForAppOpen) {
          return;
        }
        _requestAppOpen();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        break;
    }
  }

  // ─────────────────────────────────────────
  // INTERSTITIAL AD
  // ─────────────────────────────────────────

  void _loadInterstitial() {
    if (_intLoading || _interstitialAd != null) return;
    _intLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadedAt = DateTime.now();
          _intLoading = false;
        },
        onAdFailedToLoad: (_) {
          _intLoading = false;
          Future.delayed(const Duration(seconds: 8), _loadInterstitial);
        },
      ),
    );
  }

  /// Show interstitial when navigating to Saved screen.
  ///
  /// [priority] = true  → post-PDF-save: skip cooldown, always show if cap not reached.
  /// [priority] = false → manual nav tap: respect 3-min cooldown + session cap.
  void showInterstitialForSaved({bool priority = false}) {
    if (kIsWeb || _sessionShown >= _sessionCap) return;

    if (!priority) {
      final now = DateTime.now();
      if (_lastShown != null && now.difference(_lastShown!) < _cooldown) return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial(); // cache miss — load for next time
      return;
    }

    if (_isExpired(_interstitialLoadedAt, _interstitialMaxAge)) {
      ad.dispose();
      _interstitialAd = null;
      _interstitialLoadedAt = null;
      _loadInterstitial();
      return;
    }

    _interstitialAd = null;
    _interstitialLoadedAt = null;
    _sessionShown++;
    _lastShown = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _skipNextResume = false;
        _loadInterstitial();
      },
    );
    _clearPendingAppOpen();
    _skipNextResume = true;
    ad.show();
  }
}
