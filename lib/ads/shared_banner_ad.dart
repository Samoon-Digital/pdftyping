import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SharedBannerAd extends StatefulWidget {
  const SharedBannerAd({super.key, this.protectBottomInset = true});

  final bool protectBottomInset;

  @override
  State<SharedBannerAd> createState() => _SharedBannerAdState();
}

class _SharedBannerAdState extends State<SharedBannerAd> {
  static const String _androidAdUnitId =
      'ca-app-pub-1638673809508848/6182795775';
  static const int _maxRetryAttempts = 2;

  BannerAd? _bannerAd;
  AdSize? _adSize;
  Timer? _retryTimer;
  int? _requestedWidth;
  Orientation? _requestedOrientation;
  bool _hasRequestedCurrentSize = false;
  bool _isLoading = false;
  int _retryAttempts = 0;

  String? get _adUnitId {
    if (Platform.isAndroid) {
      return _androidAdUnitId;
    }
    return null;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.truncate()
            : mediaQuery.size.width.truncate();
        final orientation = mediaQuery.orientation;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _requestForSize(width, orientation);
          }
        });

        if (_bannerAd == null || _adSize == null) {
          return const SizedBox.shrink();
        }

        final banner = Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: _adSize!.width.toDouble(),
            height: _adSize!.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        );

        if (!widget.protectBottomInset) {
          return banner;
        }

        return SafeArea(left: false, top: false, right: false, child: banner);
      },
    );
  }

  Future<void> _requestForSize(
    int width,
    Orientation orientation, {
    bool retry = false,
  }) async {
    if (width <= 0 || _isLoading) {
      return;
    }

    final adUnitId = _adUnitId;
    if (adUnitId == null) {
      return;
    }

    final sameSize =
        _requestedWidth == width && _requestedOrientation == orientation;
    if (!retry && sameSize && _hasRequestedCurrentSize) {
      return;
    }

    if (!sameSize) {
      _retryTimer?.cancel();
      _retryAttempts = 0;
      _bannerAd?.dispose();
      _bannerAd = null;
      _adSize = null;
      _hasRequestedCurrentSize = false;
    }

    _requestedWidth = width;
    _requestedOrientation = orientation;
    _hasRequestedCurrentSize = true;
    _isLoading = true;

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (!mounted) {
      _isLoading = false;
      return;
    }

    if (size == null) {
      _isLoading = false;
      _scheduleRetry(width, orientation);
      return;
    }

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          _retryTimer?.cancel();
          setState(() {
            _bannerAd = ad as BannerAd;
            _adSize = size;
            _isLoading = false;
            _retryAttempts = 0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) {
            return;
          }
          setState(() {
            _bannerAd = null;
            _adSize = null;
            _isLoading = false;
          });
          _scheduleRetry(width, orientation);
        },
      ),
    );

    try {
      await bannerAd.load();
    } catch (_) {
      bannerAd.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _bannerAd = null;
        _adSize = null;
        _isLoading = false;
      });
      _scheduleRetry(width, orientation);
    }
  }

  void _scheduleRetry(int width, Orientation orientation) {
    if (_retryAttempts >= _maxRetryAttempts) {
      return;
    }

    _retryTimer?.cancel();
    final delay = Duration(seconds: 30 * (1 << _retryAttempts));
    _retryAttempts += 1;
    _retryTimer = Timer(delay, () {
      if (mounted) {
        _requestForSize(width, orientation, retry: true);
      }
    });
  }
}
