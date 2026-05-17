import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/profile/data/profile_model.dart';
import 'package:kickr/features/profile/data/profile_repository.dart';
import 'package:kickr/shared/services/storage_service.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// ─── Current user's profile ───────────────────────────────────────────────────

/// Fetches the authenticated user's full profile including role.
/// Watched by HomeScreen to determine which tab set to show.
/// Also watched by _RouterNotifier to enforce mandatory profile completion.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId =
      ref.watch(authStateProvider).valueOrNull?.session?.user.id;
  if (userId == null) return null;
  return ref.read(profileRepositoryProvider).fetchProfile(userId);
});

// ─── Profile Edit Flow ────────────────────────────────────────────────────────

class ProfileEditState {
  const ProfileEditState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.fullName = '',
    this.university = '',
    this.major = '',
    this.bio = '',
    this.skills = const [],
    this.academicYear,
    this.currentAvatarUrl,
    this.pickedAvatarBytes,
    this.pickedAvatarExt,
    this.skillInput = '',
  });

  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String fullName;
  final String university;
  final String major;
  final String bio;
  final List<String> skills;
  final String? academicYear;
  final String? currentAvatarUrl;
  final Uint8List? pickedAvatarBytes;
  final String? pickedAvatarExt;
  final String skillInput;

  bool get hasPickedAvatar => pickedAvatarBytes != null;

  ProfileEditState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? fullName,
    String? university,
    String? major,
    String? bio,
    List<String>? skills,
    String? academicYear,
    String? currentAvatarUrl,
    Uint8List? pickedAvatarBytes,
    String? pickedAvatarExt,
    String? skillInput,
    bool clearError = false,
    bool clearPickedAvatar = false,
  }) =>
      ProfileEditState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSuccess: isSuccess ?? this.isSuccess,
        fullName: fullName ?? this.fullName,
        university: university ?? this.university,
        major: major ?? this.major,
        bio: bio ?? this.bio,
        skills: skills ?? this.skills,
        academicYear: academicYear ?? this.academicYear,
        currentAvatarUrl: currentAvatarUrl ?? this.currentAvatarUrl,
        pickedAvatarBytes:
            clearPickedAvatar ? null : (pickedAvatarBytes ?? this.pickedAvatarBytes),
        pickedAvatarExt:
            clearPickedAvatar ? null : (pickedAvatarExt ?? this.pickedAvatarExt),
        skillInput: skillInput ?? this.skillInput,
      );
}

/// Auto-disposed so each edit screen session starts with a clean state.
final profileEditProvider =
    StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>(
        (ref) {
  final userId =
      ref.read(authStateProvider).valueOrNull?.session?.user.id ?? '';
  return ProfileEditNotifier(
    repository: ref.read(profileRepositoryProvider),
    storageService: ref.read(_storageServiceProvider),
    userId: userId,
    onSuccess: () {
      ref.invalidate(currentProfileProvider);
    },
  );
});

final _storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(Supabase.instance.client);
});

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  ProfileEditNotifier({
    required ProfileRepository repository,
    required StorageService storageService,
    required String userId,
    required VoidCallback onSuccess,
  })  : _repo = repository,
        _storage = storageService,
        _userId = userId,
        _onSuccess = onSuccess,
        super(const ProfileEditState());

  final ProfileRepository _repo;
  final StorageService _storage;
  final String _userId;
  final VoidCallback _onSuccess;

  /// Populates form from the loaded profile on screen open.
  void init(Profile profile) {
    state = state.copyWith(
      fullName: profile.fullName ?? '',
      university: profile.university ?? '',
      major: profile.major ?? '',
      bio: profile.bio ?? '',
      skills: List.from(profile.skills),
      academicYear: profile.academicYear,
      currentAvatarUrl: profile.avatarUrl,
    );
  }

  void setFullName(String v) => state = state.copyWith(fullName: v, clearError: true);
  void setUniversity(String v) => state = state.copyWith(university: v, clearError: true);
  void setMajor(String v) => state = state.copyWith(major: v, clearError: true);
  void setBio(String v) => state = state.copyWith(bio: v, clearError: true);
  void setAcademicYear(String v) => state = state.copyWith(academicYear: v, clearError: true);
  void setSkillInput(String v) => state = state.copyWith(skillInput: v);

  void addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty || state.skills.contains(trimmed)) return;
    state = state.copyWith(skills: [...state.skills, trimmed], skillInput: '');
  }

  void removeSkill(String skill) {
    state = state.copyWith(
      skills: state.skills.where((s) => s != skill).toList(),
    );
  }

  Future<void> pickAvatar() async {
    state = state.copyWith(clearError: true);
    try {
      final result = await _storage.pickAvatarFile();
      if (result != null) {
        state = state.copyWith(
          pickedAvatarBytes: result.bytes,
          pickedAvatarExt: result.extension,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> save() async {
    if (state.fullName.trim().isEmpty) {
      state = state.copyWith(error: 'Full name is required.');
      return;
    }
    if (_userId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      String? avatarUrl = state.currentAvatarUrl;

      if (state.hasPickedAvatar) {
        avatarUrl = await _storage.uploadAvatar(
          userId: _userId,
          bytes: state.pickedAvatarBytes!,
          extension: state.pickedAvatarExt!,
        );
      }

      await _repo.updateProfile(
        userId: _userId,
        fields: {
          'full_name': state.fullName.trim(),
          'university': state.university.trim(),
          'major': state.major.trim(),
          'bio': state.bio.trim(),
          'skills': state.skills,
          'avatar_url': avatarUrl,
          'academic_year': state.academicYear,
        },
      );

      if (mounted) {
        _onSuccess();
        state = state.copyWith(isLoading: false, isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e is StorageException ? e.message : e.toString(),
        );
      }
    }
  }
}

// ─── Mandatory Profile Completion Flow ────────────────────────────────────────

class CompleteProfileState {
  const CompleteProfileState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.fullName = '',
    this.university = '',
    this.major = '',
    this.academicYear,
    this.skills = const [],
  });

  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String fullName;
  final String university;
  final String major;
  final String? academicYear;
  final List<String> skills;

  /// All required fields are filled.
  bool get isValid =>
      fullName.trim().isNotEmpty &&
      university.trim().isNotEmpty &&
      major.trim().isNotEmpty &&
      academicYear != null &&
      skills.isNotEmpty;

  CompleteProfileState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? fullName,
    String? university,
    String? major,
    String? academicYear,
    List<String>? skills,
    bool clearError = false,
  }) =>
      CompleteProfileState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSuccess: isSuccess ?? this.isSuccess,
        fullName: fullName ?? this.fullName,
        university: university ?? this.university,
        major: major ?? this.major,
        academicYear: academicYear ?? this.academicYear,
        skills: skills ?? this.skills,
      );
}

/// Auto-disposed — fresh state each time the user lands on CompleteProfileScreen.
final completeProfileProvider =
    StateNotifierProvider.autoDispose<CompleteProfileNotifier, CompleteProfileState>(
        (ref) {
  final userId =
      ref.read(authStateProvider).valueOrNull?.session?.user.id ?? '';
  return CompleteProfileNotifier(
    repository: ref.read(profileRepositoryProvider),
    userId: userId,
    onSuccess: () => ref.invalidate(currentProfileProvider),
  );
});

class CompleteProfileNotifier extends StateNotifier<CompleteProfileState> {
  CompleteProfileNotifier({
    required ProfileRepository repository,
    required String userId,
    required VoidCallback onSuccess,
  })  : _repo = repository,
        _userId = userId,
        _onSuccess = onSuccess,
        super(const CompleteProfileState());

  final ProfileRepository _repo;
  final String _userId;
  final VoidCallback _onSuccess;

  /// Pre-fills from existing profile data (partial saves, returning users).
  void init(Profile profile) {
    state = state.copyWith(
      fullName: profile.fullName ?? '',
      university: profile.university ?? '',
      major: profile.major ?? '',
      academicYear: profile.academicYear,
      skills: List.from(profile.skills),
    );
  }

  void setFullName(String v) => state = state.copyWith(fullName: v, clearError: true);
  void setUniversity(String v) => state = state.copyWith(university: v, clearError: true);
  void setMajor(String v) => state = state.copyWith(major: v, clearError: true);
  void setAcademicYear(String v) => state = state.copyWith(academicYear: v, clearError: true);

  void addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty || state.skills.contains(trimmed)) return;
    state = state.copyWith(skills: [...state.skills, trimmed], clearError: true);
  }

  void removeSkill(String skill) {
    state = state.copyWith(
      skills: state.skills.where((s) => s != skill).toList(),
    );
  }

  Future<void> submit() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please complete all required fields.');
      return;
    }
    if (_userId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repo.updateProfile(
        userId: _userId,
        fields: {
          'full_name': state.fullName.trim(),
          'university': state.university.trim(),
          'major': state.major.trim(),
          'academic_year': state.academicYear,
          'skills': state.skills,
          'profile_completed': true,
        },
      );

      if (mounted) {
        _onSuccess(); // invalidates currentProfileProvider → router redirects to /home
        state = state.copyWith(isLoading: false, isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }
}
