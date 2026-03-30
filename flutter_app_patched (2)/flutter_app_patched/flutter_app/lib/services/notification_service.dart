import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Background FCM: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this once at app startup (before runApp or right after Firebase.initializeApp)
  static Future<void> initialize(BuildContext? context) async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS / macOS / Web)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ FCM: Permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️ FCM: Provisional permission');
    } else {
      debugPrint('❌ FCM: Permission denied');
      return;
    }

    // Get token
    try {
      final token = await _messaging.getToken();
      debugPrint('📱 FCM Token: $token');
      // TODO: Send token to backend to associate with user
    } catch (e) {
      debugPrint('FCM token error: $e');
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground FCM: ${message.notification?.title}');
      if (context != null && context.mounted) {
        _showInAppNotification(context, message);
      }
    });

    // App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Opened from FCM: ${message.data}');
      // TODO: Navigate to relevant screen based on message.data['type']
    });

    // Check if app was launched from a terminated-state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 Launched from FCM: ${initialMessage.data}');
    }
  }

  static void _showInAppNotification(
      BuildContext context, RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.notifications_rounded,
                  color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (notification.title != null)
                    Text(
                      notification.title!,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  if (notification.body != null)
                    Text(
                      notification.body!,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 12),
                      maxLines: 2,
                    ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Subscribe to a topic (e.g., 'announcements', 'canteen_updates')
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to FCM topic: $topic');
    } catch (e) {
      debugPrint('FCM subscribe error: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('FCM unsubscribe error: $e');
    }
  }
}
