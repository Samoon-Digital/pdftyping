import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_update/in_app_update.dart';

/// Checks for a Play Store update once per app session (Android only).
/// Uses flexible update when possible; falls back to immediate for critical ones.
class UpdateService {
  UpdateService._();

  static Future<void> checkForUpdate() async {
    if (kIsWeb) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {
      // Not on Play Store / no connection — silently skip.
    }
  }
}
