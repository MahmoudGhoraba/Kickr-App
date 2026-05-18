import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/app_constants.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/profile/data/profile_model.dart';
import 'package:kickr/features/profile/presentation/providers/profile_providers.dart';
import 'package:kickr/features/verification/data/verification_repository.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(Supabase.instance.client);
});

// ─── State ────────────────────────────────────────────────────────────────────

class VerificationState {
  const VerificationState({
    this.isSubmitting = false,
    this.error,
    this.resultStatus,
    this.emailInput = '',
    this.pickedIdBytes,
    this.pickedIdExt,
    this.pickedIdName,
  });

  final bool isSubmitting;
  final String? error;

  /// Set after a successful submission to drive the success UI.
  final VerificationStatus? resultStatus;

  final String emailInput;
  final Uint8List? pickedIdBytes;
  final String? pickedIdExt;
  final String? pickedIdName;

  bool get hasPickedId => pickedIdBytes != null;
  bool get isSuccess => resultStatus != null;

  VerificationState copyWith({
    bool? isSubmitting,
    String? error,
    VerificationStatus? resultStatus,
    String? emailInput,
    Uint8List? pickedIdBytes,
    String? pickedIdExt,
    String? pickedIdName,
    bool clearError = false,
    bool clearPickedId = false,
    bool clearResult = false,
  }) =>
      VerificationState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
        resultStatus: clearResult ? null : (resultStatus ?? this.resultStatus),
        emailInput: emailInput ?? this.emailInput,
        pickedIdBytes:
            clearPickedId ? null : (pickedIdBytes ?? this.pickedIdBytes),
        pickedIdExt: clearPickedId ? null : (pickedIdExt ?? this.pickedIdExt),
        pickedIdName:
            clearPickedId ? null : (pickedIdName ?? this.pickedIdName),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

final verificationNotifierProvider = StateNotifierProvider.autoDispose<
    VerificationNotifier, VerificationState>((ref) {
  final userId =
      ref.read(authStateProvider).valueOrNull?.session?.user.id ?? '';
  return VerificationNotifier(
    repository: ref.read(verificationRepositoryProvider),
    userId: userId,
    onSuccess: () => ref.invalidate(currentProfileProvider),
  );
});

class VerificationNotifier extends StateNotifier<VerificationState> {
  VerificationNotifier({
    required VerificationRepository repository,
    required String userId,
    required VoidCallback onSuccess,
  })  : _repo = repository,
        _userId = userId,
        _onSuccess = onSuccess,
        super(const VerificationState());

  final VerificationRepository _repo;
  final String _userId;
  final VoidCallback _onSuccess;

  void setEmailInput(String v) =>
      state = state.copyWith(emailInput: v, clearError: true);

  Future<void> pickStudentId() async {
    state = state.copyWith(clearError: true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file. Please try again.');
      if (bytes.lengthInBytes > AppConstants.studentIdMaxBytes) {
        throw Exception('File too large. Maximum size is 5 MB.');
      }

      state = state.copyWith(
        pickedIdBytes: bytes,
        pickedIdExt: (file.extension ?? 'jpg').toLowerCase(),
        pickedIdName: file.name,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> submitEmail() async {
    final email = state.emailInput.trim();
    if (email.isEmpty) {
      state = state.copyWith(error: 'Please enter your university email.');
      return;
    }
    if (!email.contains('@')) {
      state = state.copyWith(error: 'Enter a valid email address.');
      return;
    }
    if (_userId.isEmpty) return;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _repo.submitUniversityEmail(
        userId: _userId,
        email: email,
      );
      if (mounted) {
        _onSuccess();
        state = state.copyWith(isSubmitting: false, resultStatus: result);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSubmitting: false,
          error: e is StorageException ? e.message : e.toString(),
        );
      }
    }
  }

  Future<void> submitStudentId() async {
    if (!state.hasPickedId) {
      state = state.copyWith(error: 'Please select an image first.');
      return;
    }
    if (_userId.isEmpty) return;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.uploadStudentId(
        userId: _userId,
        bytes: state.pickedIdBytes!,
        extension: state.pickedIdExt!,
      );
      if (mounted) {
        _onSuccess();
        state = state.copyWith(
          isSubmitting: false,
          resultStatus: VerificationStatus.pending,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSubmitting: false,
          error: e is StorageException ? e.message : e.toString(),
        );
      }
    }
  }
}
