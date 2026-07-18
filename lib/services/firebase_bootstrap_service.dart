import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrapService {
  const FirebaseBootstrapService._();

  static bool _initialized = false;
  static bool _initializing = false;
  static Future<bool>? _initializationFuture;

  static bool get isInitialized => _initialized;

  static Future<bool> initialize() {
    if (_initialized) {
      return Future.value(true);
    }

    if (_initializing && _initializationFuture != null) {
      return _initializationFuture!;
    }

    _initializing = true;
    _initializationFuture = _initialize();
    return _initializationFuture!;
  }

  static Future<bool> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _initialized = true;
      return true;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _initializing = false;
    }
  }
}
