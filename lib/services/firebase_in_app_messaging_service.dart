import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap_service.dart';

class FirebaseInAppMessagingService {
  FirebaseInAppMessagingService._();

  static final FirebaseInAppMessagingService instance =
      FirebaseInAppMessagingService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final firebaseReady = await FirebaseBootstrapService.initialize();
    if (!firebaseReady) {
      return;
    }

    try {
      final messaging = FirebaseInAppMessaging.instance;
      await messaging.setAutomaticDataCollectionEnabled(true);
      await messaging.setMessagesSuppressed(false);
      await messaging.triggerEvent('app_open');
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase In-App Messaging setup skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> triggerEvent(String eventName) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_initialized) {
      return;
    }

    try {
      await FirebaseInAppMessaging.instance.triggerEvent(eventName);
    } catch (error, stackTrace) {
      debugPrint('Firebase In-App Messaging event skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
