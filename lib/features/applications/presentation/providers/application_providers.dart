import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/features/applications/data/application_model.dart';
import 'package:kickr/features/applications/data/application_repository.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/shared/services/storage_service.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository(Supabase.instance.client);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(Supabase.instance.client);
});

// ─── Saved CV URL ─────────────────────────────────────────────────────────────

/// The user's currently saved CV URL from their profile.  Invalidated after
/// a successful CV upload so the next apply sheet reflects the new file.
final userCvUrlProvider = FutureProvider<String?>((ref) {
  final userId =
      ref.watch(authStateProvider).valueOrNull?.session?.user.id;
  if (userId == null) return Future.value(null);
  return ref.read(applicationRepositoryProvider).fetchUserCvUrl(userId);
});

// ─── Applications List ────────────────────────────────────────────────────────

final applicationsProvider = StateNotifierProvider<ApplicationsNotifier,
    AsyncValue<List<Application>>>((ref) {
  final userId =
      ref.watch(authStateProvider).valueOrNull?.session?.user.id ?? '';
  return ApplicationsNotifier(
    repository: ref.watch(applicationRepositoryProvider),
    userId: userId,
  );
});

class ApplicationsNotifier
    extends StateNotifier<AsyncValue<List<Application>>> {
  ApplicationsNotifier({
    required ApplicationRepository repository,
    required String userId,
  })  : _repo = repository,
        _userId = userId,
        super(const AsyncValue.loading()) {
    fetch();
  }

  final ApplicationRepository _repo;
  final String _userId;

  Future<void> fetch() async {
    if (_userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    final result =
        await AsyncValue.guard(() => _repo.fetchUserApplications(_userId));
    if (mounted) state = result;
  }

  /// Optimistically inserts a newly submitted application at the top of the
  /// list so the Applications tab updates instantly without a re-fetch.
  void addApplication(Application application) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([application, ...current]);
  }
}

// ─── Derived: has the user already applied? ───────────────────────────────────

/// Derived from the in-memory list — no extra query.  Returns false while the
/// list is still loading (safe: the DB unique constraint is the real guard).
final hasAppliedProvider = Provider.family<bool, String>((ref, internshipId) {
  final apps = ref.watch(applicationsProvider);
  return apps.valueOrNull
          ?.any((a) => a.internshipId == internshipId) ??
      false;
});

// ─── Apply Flow ───────────────────────────────────────────────────────────────

class ApplyState {
  const ApplyState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.pickedBytes,
    this.pickedFileName,
  });

  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final Uint8List? pickedBytes;
  final String? pickedFileName;

  bool get hasFile => pickedBytes != null;

  ApplyState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    Uint8List? pickedBytes,
    String? pickedFileName,
    bool clearError = false,
    bool clearFile = false,
  }) =>
      ApplyState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSuccess: isSuccess ?? this.isSuccess,
        pickedBytes: clearFile ? null : (pickedBytes ?? this.pickedBytes),
        pickedFileName:
            clearFile ? null : (pickedFileName ?? this.pickedFileName),
      );
}

/// Auto-disposed — a fresh instance is created each time the apply sheet opens
/// and cleaned up when it closes.
final applyNotifierProvider =
    StateNotifierProvider.autoDispose<ApplyNotifier, ApplyState>((ref) {
  final userId =
      ref.read(authStateProvider).valueOrNull?.session?.user.id ?? '';

  return ApplyNotifier(
    storageService: ref.read(storageServiceProvider),
    repository: ref.read(applicationRepositoryProvider),
    userId: userId,
    onSuccess: (app) {
      ref.read(applicationsProvider.notifier).addApplication(app);
      ref.invalidate(userCvUrlProvider);
    },
  );
});

class ApplyNotifier extends StateNotifier<ApplyState> {
  ApplyNotifier({
    required StorageService storageService,
    required ApplicationRepository repository,
    required String userId,
    required void Function(Application) onSuccess,
  })  : _storage = storageService,
        _repo = repository,
        _userId = userId,
        _onSuccess = onSuccess,
        super(const ApplyState());

  final StorageService _storage;
  final ApplicationRepository _repo;
  final String _userId;
  final void Function(Application) _onSuccess;

  Future<void> pickFile() async {
    state = state.copyWith(clearError: true);
    try {
      final result = await _storage.pickCvFile();
      if (result != null) {
        state = state.copyWith(
          pickedBytes: result.bytes,
          pickedFileName: result.fileName,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> submit({
    required String internshipId,
    String? existingCvUrl,
  }) async {
    final bytes = state.pickedBytes;
    final hasExisting = existingCvUrl != null && existingCvUrl.isNotEmpty;

    if (bytes == null && !hasExisting) {
      state = state.copyWith(error: 'Please select a CV to upload.');
      return;
    }
    if (_userId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final String cvUrl;

      if (bytes != null) {
        cvUrl = await _storage.uploadCv(userId: _userId, bytes: bytes);
        await _repo.updateUserCvUrl(userId: _userId, cvUrl: cvUrl);
      } else {
        cvUrl = existingCvUrl!;
      }

      final application = await _repo.submitApplication(
        userId: _userId,
        internshipId: internshipId,
        cvUrl: cvUrl,
      );

      if (mounted) {
        _onSuccess(application);
        state = state.copyWith(isLoading: false, isSuccess: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  String _extractError(Object e) {
    if (e is StorageException) return e.message;
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return 'You have already applied to this internship.';
      }
      return e.message;
    }
    return e.toString();
  }
}
