import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad Unit IDs ──
  static const _appOpenAdUnit = 'ca-app-pub-1638673809508848/2471334449';
  static const _interstitialAdUnit = 'ca-app-pub-1638673809508848/4556898771';

  // ── App Open state ──
  AppOpenAd? _appOpenAd;
  bool _aoLoading = false;
  bool _aoShowing = false;
  // Only show when app is cold-started or resumed from background
  bool _showWhenReady = true;

  // ── Interstitial state ──
  InterstitialAd? _interstitialAd;
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
    instance._loadAppOpen();
    instance._loadInterstitial();
  }

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
          _aoLoading = false;
          if (_showWhenReady) _showAppOpenIfAvailable();
        },
        onAdFailedToLoad: (_) {
          _aoLoading = false;
          Future.delayed(const Duration(seconds: 10), _loadAppOpen);
        },
      ),
    );
  }

  void _showAppOpenIfAvailable() {
    if (_aoShowing || _appOpenAd == null) return;
    _showWhenReady = false; // reset — only show again on next app resume
    final ad = _appOpenAd!;
    _appOpenAd = null;
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
        _loadAppOpen();
      },
    );
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showWhenReady = true;
      _showAppOpenIfAvailable();
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

    _interstitialAd = null;
    _sessionShown++;
    _lastShown = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }
}
