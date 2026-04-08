import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_update/in_app_update.dart';

/// Checks for a Play Store flexible update once per app session (Android only).
class UpdateService {
  UpdateService._();

  static Future<void> checkForUpdate() async {
    if (kIsWeb) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
      if (!info.flexibleUpdateAllowed) return;

      await InAppUpdate.startFlexibleUpdate();
      // Some plugin versions do not provide an install-state stream.
      // Try completing immediately; if not ready, the call will be ignored.
      try {
        await InAppUpdate.completeFlexibleUpdate();
      } catch (_) {}
    } catch (_) {
      // Not on Play Store / no connection — silently skip.
    }
  }
}
