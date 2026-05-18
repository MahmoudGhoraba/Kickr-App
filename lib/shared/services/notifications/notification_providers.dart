import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits FCM [RemoteMessage] events received while the app is in the
/// foreground.
///
/// Listen to this from [HomeScreen] to display in-app notification banners
/// without polling or manual refresh. The stream is provided directly by
/// Firebase Messaging — no buffering or transformation.
final fcmForegroundProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessage;
});
