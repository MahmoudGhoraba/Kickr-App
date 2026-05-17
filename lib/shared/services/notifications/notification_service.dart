import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kickr/shared/services/notifications/notification_token_service.dart';

/// Top-level handler for FCM background messages.
/// Must be a top-level function (not a method) per FCM requirements.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

class NotificationService {
  const NotificationService(this._tokenService);

  final NotificationTokenService _tokenService;

  /// Initialises FCM, requests permission, registers background handler,
  /// and uploads the token to Supabase.
  Future<void> init(String userId) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _tokenService.upsertToken(userId: userId, token: token);
    }

    // Refresh token whenever FCM rotates it.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _tokenService.upsertToken(userId: userId, token: newToken);
    });

    // Handle foreground messages (no system notification by default on Android).
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    });
  }
}
