import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';

/// Flexible Play Store update flow with automatic install completion.
class UpdateService with WidgetsBindingObserver {
  UpdateService._();

  static final UpdateService _instance = UpdateService._();
  static Timer? _completeRetryTimer;
  static int _retryCount = 0;
  static bool _started = false;

  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(_instance);
    await _instance._checkForFlexibleUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_completeFlexibleUpdate());
    }
  }

  Future<void> _checkForFlexibleUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
      if (!info.flexibleUpdateAllowed) return;

      await InAppUpdate.startFlexibleUpdate();
      _scheduleAutoComplete();
      await _completeFlexibleUpdate();
    } catch (_) {
      // Not available from Play Store / no update / unsupported device.
    }
  }

  static Future<void> _completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      _completeRetryTimer?.cancel();
      _completeRetryTimer = null;
      _retryCount = 0;
    } catch (_) {
      // Update may still be downloading; retry timer handles this.
    }
  }

  void _scheduleAutoComplete() {
    _completeRetryTimer?.cancel();
    _retryCount = 0;
    _completeRetryTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      _retryCount++;
      await _completeFlexibleUpdate();
      if (_retryCount >= 12) {
        timer.cancel();
        _completeRetryTimer = null;
      }
    });
  }
}
