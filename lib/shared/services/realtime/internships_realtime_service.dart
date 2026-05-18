import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/internships/presentation/providers/internship_providers.dart';

/// Subscribes to Supabase Realtime INSERT and UPDATE events on the
/// [DatabaseConstants.internships] table.
///
/// On each event, triggers a silent background refresh of [internshipsProvider]
/// so the student feed updates automatically without a manual pull-to-refresh.
///
/// Watch this provider from [HomeScreen] to keep the subscription alive while
/// the user is authenticated. The channel is removed when the provider is
/// disposed (user logs out or navigates away from [HomeScreen]).
final internshipsRealtimeProvider = Provider.autoDispose<void>((ref) {
  final client = Supabase.instance.client;
  var disposed = false;

  final channel = client
      .channel('kickr:${DatabaseConstants.internships}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: DatabaseConstants.internships,
        callback: (_) {
          if (!disposed) {
            ref.read(internshipsProvider.notifier).backgroundRefresh();
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: DatabaseConstants.internships,
        callback: (_) {
          if (!disposed) {
            ref.read(internshipsProvider.notifier).backgroundRefresh();
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    disposed = true;
    client.removeChannel(channel);
  });
});
