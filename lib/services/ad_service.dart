import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for reward ads, interstitial ads, and template unlock state.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad Unit IDs ──
  static const _rewardAdUnit = 'ca-app-pub-1638673809508848/9816818520';
  static const _interstitialAdUnit = 'ca-app-pub-1638673809508848/4556898771';

  // ── Persistence ──
  static const _unlockPrefix = 'template_unlocked_';

  // ── Reward ad state ──
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // ── Interstitial ad state ──
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  /// Screens that have already shown an interstitial this session.
  /// Keys: 'saved', 'get_pdfs'
  final Set<String> _sessionShownScreens = {};

  // ── Initialize SDK (call once in main) ──
  static Future<void> init() async {
    if (kIsWeb) return; // Ads not supported on web
    await MobileAds.instance.initialize();
    // Pre-load both ad types in background
    AdService.instance._loadRewardAd();
    AdService.instance._loadInterstitialAd();
  }

  // ── Check if a template is unlocked ──
  Future<bool> isUnlocked(String templateId) async {
    if (kIsWeb) return true; // All templates free on web
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_unlockPrefix$templateId') ?? false;
  }

  // ── Persist unlock ──
  Future<void> _saveUnlock(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_unlockPrefix$templateId', true);
  }

  // ── Load a reward ad into memory ──
  void _loadRewardAd() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _rewardAdUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          // Retry after a short delay
          Future.delayed(const Duration(seconds: 5), () => _loadRewardAd());
        },
      ),
    );
  }

  /// Returns true if ad is ready to show.
  bool get isAdReady => _rewardedAd != null;

  /// Show the reward ad.
  /// [templateId] — which template to unlock on success.
  /// [onRewarded] — called after user earns reward + state is saved.
  /// [onAdNotReady] — called if no ad is loaded yet.
  void showRewardAd({
    required String templateId,
    required void Function() onRewarded,
    required void Function() onAdNotReady,
  }) {
    if (kIsWeb) {
      onRewarded();
      return;
    }
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewardAd(); // retry loading
      onAdNotReady();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardAd(); // pre-load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardAd();
      },
    );

    _rewardedAd = null; // prevent double-show

    ad.show(
      onUserEarnedReward: (_, reward) async {
        await _saveUnlock(templateId);
        onRewarded();
      },
    );
  }

  // ───────────────────────────────────────────────
  // ── INTERSTITIAL ADS ──
  // ───────────────────────────────────────────────

  /// Load one interstitial ad into cache.
  /// Called only after a previous interstitial is fully dismissed.
  void _loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          // Retry after delay
          Future.delayed(
            const Duration(seconds: 5),
            () => _loadInterstitialAd(),
          );
        },
      ),
    );
  }

  /// Show interstitial for [screenKey] if:
  /// - Not yet shown this session for that screen
  /// - An ad is cached and ready
  ///
  /// After dismiss, automatically queues the NEXT load.
  /// No new request is made until the current ad is fully dismissed.
  void showInterstitialIfNeeded(String screenKey) {
    if (kIsWeb) return; // No interstitials on web
    // Already shown this session for this screen — skip
    if (_sessionShownScreens.contains(screenKey)) return;

    final ad = _interstitialAd;
    if (ad == null) {
      // Ad not ready yet — skip silently (user sees screen normally)
      return;
    }

    // Mark as shown for this session immediately to prevent double-shows
    _sessionShownScreens.add(screenKey);
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        // Only after user dismisses do we request the next ad
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    ad.show();
  }
}
