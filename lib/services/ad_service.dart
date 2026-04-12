import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  // Cold start: wait up to 8 s for first network load.
  static const _coldStartWindow = Duration(seconds: 8);
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
  DateTime? _coldStartWindowUntil; // non-null only during cold-start
  bool _pendingShow = false; // true when bg→fg fired but ad was still loading
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
    instance._coldStartWindowUntil = DateTime.now().add(_coldStartWindow);
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
          // If bg→fg fired while this load was in-flight, show immediately.
          if (_pendingShow && !_appOpenIsSuppressed && !_aoShowing) {
            _pendingShow = false;
            _doShowAppOpen(ad);
          } else {
            _tryShowColdStart();
          }
        },
        onAdFailedToLoad: (_) {
          _aoLoading = false;
          Future.delayed(const Duration(seconds: 10), _loadAppOpen);
        },
      ),
    );
  }

  bool get _appOpenIsSuppressed => _appOpenSuppressionCount > 0;

  /// Cold-start path: fires from onAdLoaded; shows only if window still open.
  void _tryShowColdStart() {
    final until = _coldStartWindowUntil;
    if (until == null || until.isBefore(DateTime.now())) return;
    if (_aoShowing || _appOpenIsSuppressed) return;
    final ad = _appOpenAd;
    if (ad == null) return;
    _doShowAppOpen(ad);
  }

  /// bg→fg path: show INSTANTLY if preloaded; if in-flight, mark _pendingShow
  /// so onAdLoaded fires the show the moment the load completes.
  void _showIfPreloaded() {
    if (_aoShowing || _appOpenIsSuppressed) return;
    final ad = _appOpenAd;
    if (ad == null) {
      _pendingShow = true; // ad is loading — show as soon as it arrives
      _loadAppOpen();
      return;
    }
    if (_isExpired(_appOpenLoadedAt, _appOpenMaxAge)) {
      ad.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
      _pendingShow = true; // stale — show fresh load when it arrives
      _loadAppOpen();
      return;
    }
    _pendingShow = false;
    _doShowAppOpen(ad);
  }

  void _doShowAppOpen(AppOpenAd ad) {
    _coldStartWindowUntil = null;
    _skipNextResume = true;
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _aoShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _aoShowing = false;
        _loadAppOpen(); // preload for next open
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

  /// Call when user opens any editor — cancels cold-start window and pending show.
  void onNavigatedAway() {
    _pendingShow = false;
    _coldStartWindowUntil = null;
  }

  void pushAppOpenSuppression() {
    _appOpenSuppressionCount++;
    _pendingShow = false;
    _coldStartWindowUntil = null;
  }

  void popAppOpenSuppression() {
    if (_appOpenSuppressionCount == 0) return;
    _appOpenSuppressionCount--;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _pendingShow =
            false; // discard stale pending — fresh check on next resume
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
        _coldStartWindowUntil = null; // cold-start window no longer relevant
        _showIfPreloaded(); // instant if cached; silent preload otherwise
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
    _coldStartWindowUntil = null;
    _skipNextResume = true;
    ad.show();
  }
}
