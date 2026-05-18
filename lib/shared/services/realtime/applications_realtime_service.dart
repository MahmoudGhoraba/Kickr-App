import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/applications/presentation/providers/application_providers.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';

/// Subscribes to Supabase Realtime UPDATE events on the
/// [DatabaseConstants.applications] table (no server-side row filter).
///
/// A server-side filter on user_id requires REPLICA IDENTITY FULL on the
/// table to work reliably for UPDATE events; omitting it is simpler and
/// equally secure because [ApplicationsNotifier.backgroundRefresh] fetches
/// only the current user's rows via RLS-protected queries.
///
/// When any application row is updated (status change by a company), this
/// provider triggers a silent re-fetch for the current user. Users without
/// a pending update incur one lightweight query but see no UI change.
///
/// Watch this provider from [HomeScreen] to keep the channel alive while
/// the user is authenticated. It is a no-op when [userId] is unavailable.
final applicationsRealtimeProvider = Provider.autoDispose<void>((ref) {
  final userId =
      ref.read(authStateProvider).valueOrNull?.session?.user.id;

  if (userId == null || userId.isEmpty) return;

  final client = Supabase.instance.client;
  var disposed = false;

  final channel = client
      .channel('kickr:${DatabaseConstants.applications}')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: DatabaseConstants.applications,
        callback: (_) {
          if (!disposed) {
            ref.read(applicationsProvider.notifier).backgroundRefresh();
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    disposed = true;
    client.removeChannel(channel);
  });
});
