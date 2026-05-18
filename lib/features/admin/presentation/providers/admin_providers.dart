import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/features/admin/data/admin_repository.dart';
import 'package:kickr/features/admin/data/verification_review_entry.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

// ─── Filter ───────────────────────────────────────────────────────────────────

/// Active status filter for the admin verification list.
/// Null means show all students regardless of status.
final adminVerificationFilterProvider =
    StateProvider<VerificationStatus?>((ref) => VerificationStatus.pending);

// ─── All verifications ────────────────────────────────────────────────────────

final verificationsProvider = StateNotifierProvider<
    VerificationsNotifier, AsyncValue<List<VerificationReviewEntry>>>((ref) {
  return VerificationsNotifier(
    repository: ref.read(adminRepositoryProvider),
  );
});

class VerificationsNotifier
    extends StateNotifier<AsyncValue<List<VerificationReviewEntry>>> {
  VerificationsNotifier({required AdminRepository repository})
      : _repo = repository,
        super(const AsyncValue.loading()) {
    _load();
  }

  final AdminRepository _repo;

  Future<void> _load() async {
    // Fetch all students — filtering is done in memory via filteredVerificationsProvider.
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repo.fetchVerifications(),
    );
    if (mounted) state = result;
  }

  Future<void> refresh() => _load();

  Future<void> approve(String userId) async {
    await _repo.approveVerification(userId);
    _patchStatus(userId, VerificationStatus.verified);
  }

  Future<void> reject(String userId) async {
    await _repo.rejectVerification(userId);
    _patchStatus(userId, VerificationStatus.unverified);
  }

  void _patchStatus(String userId, VerificationStatus status) {
    final current = state.valueOrNull ?? [];
    if (!mounted) return;
    state = AsyncValue.data([
      for (final e in current)
        if (e.userId == userId)
          VerificationReviewEntry(
            userId: e.userId,
            fullName: e.fullName,
            university: e.university,
            universityEmail: e.universityEmail,
            studentIdUrl: e.studentIdUrl,
            avatarUrl: e.avatarUrl,
            verificationStatus: status,
            verifiedAt:
                status == VerificationStatus.verified ? DateTime.now() : null,
            createdAt: e.createdAt,
          )
        else
          e,
    ]);
  }
}

// ─── Derived ─────────────────────────────────────────────────────────────────

/// Verifications filtered by the active status chip.
final filteredVerificationsProvider =
    Provider<AsyncValue<List<VerificationReviewEntry>>>((ref) {
  final filter = ref.watch(adminVerificationFilterProvider);
  return ref.watch(verificationsProvider).whenData((list) {
    if (filter == null) return list;
    return list.where((e) => e.verificationStatus == filter).toList();
  });
});

/// Count of students currently in pending review — drives the badge on the
/// Pending filter chip so the admin immediately knows the work queue size.
final pendingCountProvider = Provider<int>((ref) {
  return ref
          .watch(verificationsProvider)
          .valueOrNull
          ?.where((e) => e.verificationStatus == VerificationStatus.pending)
          .length ??
      0;
});
