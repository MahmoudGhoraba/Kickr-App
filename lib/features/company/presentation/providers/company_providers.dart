import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/features/applications/data/application_model.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/company/data/applicant_entry.dart';
import 'package:kickr/features/company/data/company_repository.dart';
import 'package:kickr/features/internships/data/company_model.dart';
import 'package:kickr/features/internships/data/internship_model.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(Supabase.instance.client);
});

// ─── Current owner's company ──────────────────────────────────────────────────

final currentCompanyProvider = FutureProvider<Company?>((ref) async {
  final userId =
      ref.watch(authStateProvider).valueOrNull?.session?.user.id;
  if (userId == null) return null;
  return ref.read(companyRepositoryProvider).fetchCompanyByOwner(userId);
});

// ─── Company's internship list ────────────────────────────────────────────────

final companyInternshipsProvider = StateNotifierProvider<
    CompanyInternshipsNotifier, AsyncValue<List<Internship>>>((ref) {
  final companyId =
      ref.watch(currentCompanyProvider).valueOrNull?.id;
  return CompanyInternshipsNotifier(
    repository: ref.watch(companyRepositoryProvider),
    companyId: companyId,
  );
});

class CompanyInternshipsNotifier
    extends StateNotifier<AsyncValue<List<Internship>>> {
  CompanyInternshipsNotifier({
    required CompanyRepository repository,
    required String? companyId,
  })  : _repo = repository,
        _companyId = companyId,
        super(const AsyncValue.loading()) {
    _load();
  }

  final CompanyRepository _repo;
  final String? _companyId;

  Future<void> _load() async {
    final id = _companyId;
    if (id == null || id.isEmpty) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    final result =
        await AsyncValue.guard(() => _repo.fetchCompanyInternships(id));
    if (mounted) state = result;
  }

  Future<void> refresh() => _load();

  void addInternship(Internship internship) {
    final current = state.valueOrNull ?? [];
    if (mounted) state = AsyncValue.data([internship, ...current]);
  }

  void updateInternship(Internship updated) {
    final current = state.valueOrNull ?? [];
    if (mounted) {
      state = AsyncValue.data([
        for (final i in current) i.id == updated.id ? updated : i,
      ]);
    }
  }

  void removeInternship(String internshipId) {
    final current = state.valueOrNull ?? [];
    if (mounted) {
      state = AsyncValue.data(
          current.where((i) => i.id != internshipId).toList());
    }
  }
}

// ─── Applicant list (per internship) ─────────────────────────────────────────

final applicantsProvider =
    StateNotifierProvider.autoDispose.family<ApplicantsNotifier,
        AsyncValue<List<ApplicantEntry>>, String>((ref, internshipId) {
  return ApplicantsNotifier(
    repository: ref.read(companyRepositoryProvider),
    internshipId: internshipId,
  );
});

class ApplicantsNotifier
    extends StateNotifier<AsyncValue<List<ApplicantEntry>>> {
  ApplicantsNotifier({
    required CompanyRepository repository,
    required String internshipId,
  })  : _repo = repository,
        _internshipId = internshipId,
        super(const AsyncValue.loading()) {
    _load();
  }

  final CompanyRepository _repo;
  final String _internshipId;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result =
        await AsyncValue.guard(() => _repo.fetchApplicants(_internshipId));
    if (mounted) state = result;
  }

  Future<void> refresh() => _load();

  Future<void> updateStatus(
      String applicationId, ApplicationStatus status) async {
    await _repo.updateApplicationStatus(
        applicationId: applicationId, status: status);
    // Reflect the change locally so the UI updates without a full reload
    final current = state.valueOrNull ?? [];
    if (mounted) {
      state = AsyncValue.data([
        for (final entry in current)
          if (entry.application.id == applicationId)
            ApplicantEntry(
              application: Application(
                id: entry.application.id,
                userId: entry.application.userId,
                internshipId: entry.application.internshipId,
                cvUrl: entry.application.cvUrl,
                status: status,
                createdAt: entry.application.createdAt,
                updatedAt: DateTime.now(),
              ),
              fullName: entry.fullName,
              university: entry.university,
              major: entry.major,
              avatarUrl: entry.avatarUrl,
            )
          else
            entry,
      ]);
    }
  }
}

// ─── Company setup form ───────────────────────────────────────────────────────

class CompanySetupState {
  const CompanySetupState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  final bool isLoading;
  final String? error;
  final bool isSuccess;

  CompanySetupState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool clearError = false,
  }) =>
      CompanySetupState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

final companySetupProvider =
    StateNotifierProvider.autoDispose<CompanySetupNotifier, CompanySetupState>(
        (ref) {
  final userId =
      ref.read(authStateProvider).valueOrNull?.session?.user.id ?? '';
  return CompanySetupNotifier(
    repository: ref.read(companyRepositoryProvider),
    ownerId: userId,
    onSuccess: () {
      ref.invalidate(currentCompanyProvider);
      ref.invalidate(companyInternshipsProvider);
    },
  );
});

class CompanySetupNotifier extends StateNotifier<CompanySetupState> {
  CompanySetupNotifier({
    required CompanyRepository repository,
    required String ownerId,
    required VoidCallback onSuccess,
  })  : _repo = repository,
        _ownerId = ownerId,
        _onSuccess = onSuccess,
        super(const CompanySetupState());

  final CompanyRepository _repo;
  final String _ownerId;
  final VoidCallback _onSuccess;

  Future<void> create({
    required String name,
    String? description,
    String? industry,
    String? location,
    String? website,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Company name is required.');
      return;
    }
    if (_ownerId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.createCompany(
        ownerId: _ownerId,
        name: name.trim(),
        description: description,
        industry: industry,
        location: location,
        website: website,
      );
      if (mounted) {
        _onSuccess();
        state = state.copyWith(isLoading: false, isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: _extractError(e));
      }
    }
  }

  String _extractError(Object e) {
    if (e is PostgrestException) return 'Could not create company. Please try again.';
    return 'Something went wrong. Please try again.';
  }
}

// ─── Internship form (create / edit) ─────────────────────────────────────────

class InternshipFormState {
  const InternshipFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.title = '',
    this.description = '',
    this.shortDescription = '',
    this.location = '',
    this.type = InternshipType.onsite,
    this.category = '',
    this.skills = const [],
    this.isActive = true,
    this.skillInput = '',
  });

  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String title;
  final String description;
  final String shortDescription;
  final String location;
  final InternshipType type;
  final String category;
  final List<String> skills;
  final bool isActive;
  final String skillInput;

  InternshipFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? title,
    String? description,
    String? shortDescription,
    String? location,
    InternshipType? type,
    String? category,
    List<String>? skills,
    bool? isActive,
    String? skillInput,
    bool clearError = false,
  }) =>
      InternshipFormState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSuccess: isSuccess ?? this.isSuccess,
        title: title ?? this.title,
        description: description ?? this.description,
        shortDescription: shortDescription ?? this.shortDescription,
        location: location ?? this.location,
        type: type ?? this.type,
        category: category ?? this.category,
        skills: skills ?? this.skills,
        isActive: isActive ?? this.isActive,
        skillInput: skillInput ?? this.skillInput,
      );
}

final internshipFormProvider = StateNotifierProvider.autoDispose<
    InternshipFormNotifier, InternshipFormState>((ref) {
  return InternshipFormNotifier(
    repository: ref.read(companyRepositoryProvider),
    onCreated: (i) =>
        ref.read(companyInternshipsProvider.notifier).addInternship(i),
    onUpdated: (i) =>
        ref.read(companyInternshipsProvider.notifier).updateInternship(i),
  );
});

class InternshipFormNotifier extends StateNotifier<InternshipFormState> {
  InternshipFormNotifier({
    required CompanyRepository repository,
    required void Function(Internship) onCreated,
    required void Function(Internship) onUpdated,
  })  : _repo = repository,
        _onCreated = onCreated,
        _onUpdated = onUpdated,
        super(const InternshipFormState());

  final CompanyRepository _repo;
  final void Function(Internship) _onCreated;
  final void Function(Internship) _onUpdated;

  void init(Internship internship) {
    state = state.copyWith(
      title: internship.title,
      description: internship.description,
      shortDescription: internship.shortDescription ?? '',
      location: internship.location,
      type: internship.type,
      category: internship.category ?? '',
      skills: List.from(internship.requiredSkills),
      isActive: internship.isActive,
    );
  }

  void setTitle(String v) => state = state.copyWith(title: v, clearError: true);
  void setDescription(String v) =>
      state = state.copyWith(description: v, clearError: true);
  void setShortDescription(String v) =>
      state = state.copyWith(shortDescription: v);
  void setLocation(String v) =>
      state = state.copyWith(location: v, clearError: true);
  void setType(InternshipType v) => state = state.copyWith(type: v);
  void setCategory(String v) => state = state.copyWith(category: v);
  void setIsActive(bool v) => state = state.copyWith(isActive: v);
  void setSkillInput(String v) => state = state.copyWith(skillInput: v);

  void addSkill() {
    final skill = state.skillInput.trim();
    if (skill.isEmpty || state.skills.contains(skill)) {
      state = state.copyWith(skillInput: '');
      return;
    }
    state = state.copyWith(skills: [...state.skills, skill], skillInput: '');
  }

  void removeSkill(String skill) {
    state = state.copyWith(
        skills: state.skills.where((s) => s != skill).toList());
  }

  Future<void> submit({
    required String companyId,
    String? internshipId,
  }) async {
    if (state.title.trim().isEmpty) {
      state = state.copyWith(error: 'Title is required.');
      return;
    }
    if (state.description.trim().isEmpty) {
      state = state.copyWith(error: 'Description is required.');
      return;
    }
    if (state.location.trim().isEmpty) {
      state = state.copyWith(error: 'Location is required.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Internship result;

      if (internshipId == null) {
        result = await _repo.createInternship(
          companyId: companyId,
          title: state.title.trim(),
          description: state.description.trim(),
          shortDescription: state.shortDescription.trim().isEmpty
              ? null
              : state.shortDescription.trim(),
          location: state.location.trim(),
          type: state.type,
          category: state.category.trim().isEmpty ? null : state.category.trim(),
          requiredSkills: state.skills,
        );
      } else {
        result = await _repo.updateInternship(
          internshipId: internshipId,
          title: state.title.trim(),
          description: state.description.trim(),
          shortDescription: state.shortDescription.trim().isEmpty
              ? null
              : state.shortDescription.trim(),
          location: state.location.trim(),
          type: state.type,
          category: state.category.trim().isEmpty ? null : state.category.trim(),
          requiredSkills: state.skills,
          isActive: state.isActive,
        );
      }

      if (mounted) {
        if (internshipId == null) {
          _onCreated(result);
        } else {
          _onUpdated(result);
        }
        state = state.copyWith(isLoading: false, isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: _extractError(e));
      }
    }
  }

  String _extractError(Object e) {
    if (e is PostgrestException) return 'Could not save internship. Please try again.';
    return 'Something went wrong. Please try again.';
  }
}
