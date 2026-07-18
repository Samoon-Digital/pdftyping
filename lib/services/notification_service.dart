import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/app_open_ad_manager.dart';
import 'firebase_bootstrap_service.dart';

const AndroidNotificationChannel appNotificationChannel =
    AndroidNotificationChannel(
      'aadhaar_update_guide_updates',
      'Aadhaar Update Guide',
      description: 'Important app updates and announcements.',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (error) {
    debugPrint('Background Firebase initialization skipped: $error');
  }
}

void registerFirebaseMessagingBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _permissionGrantedKey =
      'notifications_permission_granted';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _initialized = false;
  bool _localNotificationsInitialized = false;
  bool _permissionPromptShownThisSession = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _ensureLocalNotificationsInitialized();

    final firebaseReady = await FirebaseBootstrapService.initialize();
    if (!firebaseReady) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageTap(initialMessage);
      }

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleRemoteMessageTap,
      );
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (token) => debugPrint('Current FCM Token: $token'),
      );

      await printCurrentToken();
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase Messaging setup skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> printCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('Current FCM Token: ${token ?? 'Unavailable'}');
    } catch (error) {
      debugPrint('Current FCM Token: Unavailable ($error)');
    }
  }

  Future<void> showPermissionDialogIfNeeded(BuildContext context) async {
    if (_permissionPromptShownThisSession || !context.mounted) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionGrantedKey) == true) {
      return;
    }

    await _ensureLocalNotificationsInitialized();

    final alreadyGranted = await _areNotificationsEnabled();
    if (alreadyGranted) {
      await prefs.setBool(_permissionGrantedKey, true);
      return;
    }

    _permissionPromptShownThisSession = true;
    if (!context.mounted) {
      return;
    }

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 6),
        actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Color(0xFF1565C0)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Stay Updated',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Never miss important updates from the app.',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            SizedBox(height: 14),
            Text(
              'Enable notifications to receive:',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            _PermissionPoint(
              icon: Icons.auto_awesome_rounded,
              text: 'New features and improvements',
            ),
            _PermissionPoint(
              icon: Icons.campaign_rounded,
              text: 'Important announcements',
            ),
            _PermissionPoint(
              icon: Icons.rocket_launch_rounded,
              text: 'Helpful updates and information',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) {
      return;
    }

    final granted = await _requestNotificationPermission();
    if (granted) {
      await prefs.setBool(_permissionGrantedKey, true);
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _ensureLocalNotificationsInitialized() async {
    if (_localNotificationsInitialized) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(appNotificationChannel);

    _localNotificationsInitialized = true;
  }

  Future<bool> _areNotificationsEnabled() async {
    try {
      final notificationStatus = await Permission.notification.status;
      if (notificationStatus.isGranted || notificationStatus.isLimited) {
        return true;
      }
      if (notificationStatus.isDenied ||
          notificationStatus.isPermanentlyDenied ||
          notificationStatus.isRestricted) {
        return false;
      }

      final androidEnabled = await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      if (androidEnabled != null) {
        return androidEnabled;
      }

      if (FirebaseBootstrapService.isInitialized) {
        final settings = await FirebaseMessaging.instance
            .getNotificationSettings();
        return _isAuthorized(settings.authorizationStatus);
      }
    } catch (error) {
      debugPrint('Notification permission status unavailable: $error');
    }

    return false;
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      final permissionStatus = await Permission.notification.request();
      if (permissionStatus.isGranted || permissionStatus.isLimited) {
        return true;
      }
      if (permissionStatus.isDenied ||
          permissionStatus.isPermanentlyDenied ||
          permissionStatus.isRestricted) {
        return false;
      }

      final androidGranted = await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (androidGranted != null) {
        return androidGranted;
      }

      final firebaseReady = await FirebaseBootstrapService.initialize();
      if (!firebaseReady) {
        return false;
      }

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return _isAuthorized(settings.authorizationStatus);
    } catch (error, stackTrace) {
      debugPrint('Notification permission request skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  bool _isAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final id = message.messageId?.hashCode ?? DateTime.now().hashCode;
    await _localNotifications.show(
      id: id & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          appNotificationChannel.id,
          appNotificationChannel.name,
          channelDescription: appNotificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    _openDeepLink(message.data);
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _openDeepLink(decoded);
      }
    } catch (error) {
      debugPrint('Notification payload ignored: $error');
    }
  }

  void _openDeepLink(Map<String, dynamic> data) {
    final target =
        data['deep_link'] as String? ??
        data['deeplink'] as String? ??
        data['route'] as String?;

    if (target == null || target.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = AppOpenAdManager.instance.navigatorKey.currentState;
      if (navigator == null) {
        return;
      }

      final uri = Uri.tryParse(target);
      final normalizedTarget = target.toLowerCase();
      final path = uri?.path.toLowerCase() ?? normalizedTarget;

      if (normalizedTarget == 'home' ||
          path == '/home' ||
          path == '/' ||
          uri?.host.toLowerCase() == 'home') {
        navigator.popUntil((route) => route.isFirst);
      }
    });
  }
}

class _PermissionPoint extends StatelessWidget {
  const _PermissionPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.2, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
