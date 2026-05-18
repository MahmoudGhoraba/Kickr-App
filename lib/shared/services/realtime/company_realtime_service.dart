import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/company/presentation/providers/company_providers.dart';

/// Subscribes to Supabase Realtime INSERT events on the
/// [DatabaseConstants.applications] table for the current company.
///
/// When a student submits an application, the company's
/// [companyInternshipsProvider] is silently refreshed so the application
/// count on the dashboard updates immediately — no pull-to-refresh needed.
///
/// No server-side filter is used because applications rows don't carry a
/// company_id column. Instead, the callback reads the in-memory
/// [companyInternshipsProvider] list and only triggers a refresh when the
/// incoming [internship_id] belongs to this company.
///
/// This provider is a no-op for student accounts — it returns early when
/// [currentCompanyProvider] has no value.
final companyApplicationsRealtimeProvider = Provider.autoDispose<void>((ref) {
  final companyId =
      ref.watch(currentCompanyProvider).valueOrNull?.id;

  if (companyId == null || companyId.isEmpty) return;

  final client = Supabase.instance.client;
  var disposed = false;

  final channel = client
      .channel('kickr:applications:company:$companyId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: DatabaseConstants.applications,
        callback: (payload) {
          if (disposed) return;

          final internshipId =
              payload.newRecord['internship_id'] as String?;
          if (internshipId == null) return;

          // Only act when the new application targets this company's internship.
          // Read current state without creating a dependency (safe in callbacks).
          final owned = ref
              .read(companyInternshipsProvider)
              .valueOrNull
              ?.any((i) => i.id == internshipId) ??
              false;

          if (owned) {
            ref.read(companyInternshipsProvider.notifier).refresh();
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    disposed = true;
    client.removeChannel(channel);
  });
});
