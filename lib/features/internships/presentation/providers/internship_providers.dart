import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/internships/data/internship_repository.dart';

// ─── Repository ─────────────────────────────────────────────────────────────

final internshipRepositoryProvider = Provider<InternshipRepository>((ref) {
  return InternshipRepository(Supabase.instance.client);
});

// ─── Internship List ─────────────────────────────────────────────────────────

final internshipsProvider =
    StateNotifierProvider<InternshipsNotifier, AsyncValue<List<Internship>>>(
        (ref) {
  return InternshipsNotifier(ref.watch(internshipRepositoryProvider));
});

class InternshipsNotifier
    extends StateNotifier<AsyncValue<List<Internship>>> {
  InternshipsNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetch();
  }

  final InternshipRepository _repo;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_repo.fetchInternships);
    if (mounted) state = result;
  }
}

// ─── Filter ──────────────────────────────────────────────────────────────────

class InternshipFilter {
  const InternshipFilter({
    this.query = '',
    this.selectedTypes = const <InternshipType>{},
  });

  final String query;
  final Set<InternshipType> selectedTypes;

  bool get isEmpty => query.isEmpty && selectedTypes.isEmpty;

  InternshipFilter copyWith({
    String? query,
    Set<InternshipType>? selectedTypes,
  }) {
    return InternshipFilter(
      query: query ?? this.query,
      selectedTypes: selectedTypes ?? this.selectedTypes,
    );
  }
}

final internshipFilterProvider =
    StateNotifierProvider<InternshipFilterNotifier, InternshipFilter>((ref) {
  return InternshipFilterNotifier();
});

class InternshipFilterNotifier extends StateNotifier<InternshipFilter> {
  InternshipFilterNotifier() : super(const InternshipFilter());

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleType(InternshipType type) {
    final updated = {...state.selectedTypes};
    if (updated.contains(type)) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    state = state.copyWith(selectedTypes: updated);
  }

  void clearAll() => state = const InternshipFilter();
}

// Derived filtered list — no additional Supabase query
final filteredInternshipsProvider =
    Provider<AsyncValue<List<Internship>>>((ref) {
  final internships = ref.watch(internshipsProvider);
  final filter = ref.watch(internshipFilterProvider);

  return internships.whenData((list) {
    var result = list;

    if (filter.query.isNotEmpty) {
      final q = filter.query.toLowerCase();
      result = result.where((i) {
        return i.title.toLowerCase().contains(q) ||
            (i.company?.name.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (filter.selectedTypes.isNotEmpty) {
      result = result
          .where((i) => filter.selectedTypes.contains(i.type))
          .toList();
    }

    return result;
  });
});

// ─── Saved Internships ────────────────────────────────────────────────────────

final savedInternshipIdsProvider = StateNotifierProvider<SavedInternshipsNotifier,
    AsyncValue<Set<String>>>((ref) {
  final repo = ref.watch(internshipRepositoryProvider);
  final auth = ref.read(authStateProvider);
  final userId = auth.valueOrNull?.session?.user.id ?? '';
  return SavedInternshipsNotifier(repo: repo, userId: userId);
});

class SavedInternshipsNotifier
    extends StateNotifier<AsyncValue<Set<String>>> {
  SavedInternshipsNotifier({
    required InternshipRepository repo,
    required String userId,
  })  : _repo = repo,
        _userId = userId,
        super(const AsyncValue.loading()) {
    _load();
  }

  final InternshipRepository _repo;
  final String _userId;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result =
        await AsyncValue.guard(() => _repo.fetchSavedInternshipIds(_userId));
    if (mounted) state = result;
  }

  Future<void> toggle(String internshipId) async {
    final current = state.valueOrNull ?? <String>{};
    final isSaved = current.contains(internshipId);

    // Optimistic update
    state = AsyncValue.data(
      isSaved
          ? ({...current}..remove(internshipId))
          : {...current, internshipId},
    );

    try {
      if (isSaved) {
        await _repo.unsaveInternship(
            userId: _userId, internshipId: internshipId);
      } else {
        await _repo.saveInternship(
            userId: _userId, internshipId: internshipId);
      }
    } catch (_) {
      state = AsyncValue.data(current); // rollback on failure
    }
  }
}

// Derives full saved internship objects from the main list + saved IDs
final savedInternshipListProvider =
    Provider<AsyncValue<List<Internship>>>((ref) {
  final all = ref.watch(internshipsProvider);
  final ids = ref.watch(savedInternshipIdsProvider);

  if (all.isLoading || ids.isLoading) return const AsyncValue.loading();
  if (all.hasError) return AsyncValue.error(all.error!, all.stackTrace!);
  if (ids.hasError) return AsyncValue.error(ids.error!, ids.stackTrace!);

  final idSet = ids.requireValue;
  return AsyncValue.data(
    all.requireValue.where((i) => idSet.contains(i.id)).toList(),
  );
});

// ─── Detail ───────────────────────────────────────────────────────────────────

final internshipDetailProvider =
    FutureProvider.family<Internship, String>((ref, id) {
  return ref.watch(internshipRepositoryProvider).fetchInternshipById(id);
});
