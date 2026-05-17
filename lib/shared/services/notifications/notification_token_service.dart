import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';

class NotificationTokenService {
  const NotificationTokenService(this._supabase);

  final SupabaseClient _supabase;

  /// Upserts the FCM token for [userId].
  /// On conflict (user_id + token already stored) this is a no-op,
  /// so safe to call on every app launch.
  Future<void> upsertToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _supabase.from(DatabaseConstants.notificationTokens).upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
        },
        onConflict: 'user_id,token',
      );
    } catch (e) {
      debugPrint('Failed to upsert notification token: $e');
    }
  }

  /// Removes the FCM token on sign-out so the user no longer receives
  /// notifications on this device.
  Future<void> deleteToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _supabase
          .from(DatabaseConstants.notificationTokens)
          .delete()
          .match({'user_id': userId, 'token': token});
    } catch (e) {
      debugPrint('Failed to delete notification token: $e');
    }
  }
}
