import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for reward ads and template unlock state.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad Unit IDs ──
  static const _rewardAdUnit = 'ca-app-pub-1638673809508848/9816818520';

  // ── Persistence ──
  static const _unlockPrefix = 'template_unlocked_';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // ── Initialize SDK (call once in main) ──
  static Future<void> init() async {
    await MobileAds.instance.initialize();
    // Pre-load the first reward ad
    AdService.instance._loadRewardAd();
  }

  // ── Check if a template is unlocked ──
  Future<bool> isUnlocked(String templateId) async {
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
}
