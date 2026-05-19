import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum ScreenInterstitialPlacement {
  aadhaar5To18,
  aadhaar18Plus,
  addressUpdate,
  biometricUpdate,
  childBalAadhaar,
  dobUpdate,
  mobileUpdate,
  nameUpdate,
  ratecard,
  relationshipDocument,
}

extension ScreenInterstitialPlacementX on ScreenInterstitialPlacement {
  String get adUnitId {
    switch (this) {
      case ScreenInterstitialPlacement.aadhaar5To18:
        return 'ca-app-pub-1638673809508848/2231643751';
      case ScreenInterstitialPlacement.aadhaar18Plus:
        return 'ca-app-pub-1638673809508848/3068562799';
      case ScreenInterstitialPlacement.addressUpdate:
        return 'ca-app-pub-1638673809508848/7048022019';
      case ScreenInterstitialPlacement.biometricUpdate:
        return 'ca-app-pub-1638673809508848/5787745385';
      case ScreenInterstitialPlacement.childBalAadhaar:
        return 'ca-app-pub-1638673809508848/5926512032';
      case ScreenInterstitialPlacement.dobUpdate:
        return 'ca-app-pub-1638673809508848/3255053604';
      case ScreenInterstitialPlacement.mobileUpdate:
        return 'ca-app-pub-1638673809508848/1848500378';
      case ScreenInterstitialPlacement.nameUpdate:
        return 'ca-app-pub-1638673809508848/8605480413';
      case ScreenInterstitialPlacement.ratecard:
        return 'ca-app-pub-1638673809508848/3063481917';
      case ScreenInterstitialPlacement.relationshipDocument:
        return 'ca-app-pub-1638673809508848/8129317787';
    }
  }
}

class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  // Cold start: wait up to 8 s for first network load.
  static const _coldStartWindow = Duration(seconds: 8);
  static const _minBackgroundForAppOpen = Duration(seconds: 2);
  static const _appOpenMaxAge = Duration(hours: 4);
  static const _screenInterstitialSessionCap = 4;
  static const _screenInterstitialCooldown = Duration(seconds: 45);
  static const _samePlacementCooldown = Duration(minutes: 2);
  static const _screenInterstitialLoadWindow = Duration(seconds: 6);

  // ── Ad Unit IDs ──
  static const _appOpenAdUnit = 'ca-app-pub-1638673809508848/2471334449';

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

  // ── Screen-entry interstitial state ──
  int _screenInterstitialRequestToken = 0;
  bool _screenInterstitialShowing = false;
  int _screenInterstitialShown = 0;
  DateTime? _lastScreenInterstitialShownAt;
  final Map<ScreenInterstitialPlacement, DateTime> _lastPlacementShownAt =
      <ScreenInterstitialPlacement, DateTime>{};

  // ── Init (call once in main) ──
  static Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(instance);
    instance._coldStartWindowUntil = DateTime.now().add(_coldStartWindow);
    instance._loadAppOpen();
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
  // SCREEN-ENTRY INTERSTITIAL AD
  // ─────────────────────────────────────────

  void loadAndShowScreenInterstitial({
    required ScreenInterstitialPlacement placement,
    required bool Function() canShow,
  }) {
    if (kIsWeb || _aoShowing || _screenInterstitialShowing) return;

    final now = DateTime.now();
    if (_screenInterstitialShown >= _screenInterstitialSessionCap) return;
    if (_lastScreenInterstitialShownAt != null &&
        now.difference(_lastScreenInterstitialShownAt!) <
            _screenInterstitialCooldown) {
      return;
    }

    final placementShownAt = _lastPlacementShownAt[placement];
    if (placementShownAt != null &&
        now.difference(placementShownAt) < _samePlacementCooldown) {
      return;
    }

    _pendingShow = false;
    _coldStartWindowUntil = null;

    final requestToken = ++_screenInterstitialRequestToken;
    final requestedAt = now;

    InterstitialAd.load(
      adUnitId: placement.adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          final isFreshLoad =
              DateTime.now().difference(requestedAt) <=
              _screenInterstitialLoadWindow;
          if (requestToken != _screenInterstitialRequestToken ||
              !isFreshLoad ||
              !canShow()) {
            ad.dispose();
            return;
          }

          final shownAt = DateTime.now();
          _screenInterstitialShowing = true;
          _screenInterstitialShown++;
          _lastScreenInterstitialShownAt = shownAt;
          _lastPlacementShownAt[placement] = shownAt;
          _skipNextResume = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _screenInterstitialShowing = false;
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _screenInterstitialShowing = false;
              _skipNextResume = false;
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }
}
