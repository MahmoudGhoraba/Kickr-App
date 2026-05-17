import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/core/router/app_router.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/internships/presentation/providers/internship_providers.dart';
import 'package:kickr/features/internships/presentation/widgets/internship_card.dart';
import 'package:kickr/features/internships/presentation/widgets/internship_filter_bar.dart';
import 'package:kickr/features/profile/presentation/providers/profile_providers.dart';
import 'package:kickr/shared/widgets/app_button.dart';
import 'package:kickr/shared/widgets/app_search_bar.dart';

String _buildSearchLabel(InternshipFilter filter) {
  final parts = <String>[];
  if (filter.query.isNotEmpty) parts.add('"${filter.query}"');
  if (filter.selectedTypes.isNotEmpty) {
    parts.add(filter.selectedTypes.map((t) => t.label).join(', '));
  }
  return parts.join(' · ');
}

class InternshipFeedScreen extends ConsumerStatefulWidget {
  const InternshipFeedScreen({super.key});

  @override
  ConsumerState<InternshipFeedScreen> createState() =>
      _InternshipFeedScreenState();
}

class _InternshipFeedScreenState
    extends ConsumerState<InternshipFeedScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _firstName(String? fullName) {
    final trimmed = (fullName ?? '').trim();
    if (trimmed.isEmpty) return 'Student';
    return trimmed.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final internships = ref.watch(filteredInternshipsProvider);
    final filter = ref.watch(internshipFilterProvider);
    final firstName = _firstName(
      ref.watch(currentProfileProvider).valueOrNull?.fullName,
    );

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(internshipsProvider.notifier).fetch(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Greeting(firstName: firstName),
                    const SizedBox(height: 20),
                    AppSearchBar(
                      controller: _searchController,
                      hintText: 'Search internships...',
                      onChanged: (q) =>
                          ref.read(internshipFilterProvider.notifier).setQuery(q),
                    ),
                    const SizedBox(height: 12),
                    const InternshipFilterBar(),
                    if (!filter.isEmpty) ...[
                      const SizedBox(height: 8),
                      _SaveSearchBar(filter: filter),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            internships.when(
              loading: () =>
                  const SliverFillRemaining(child: _LoadingState()),
              error: (_, _) => SliverFillRemaining(
                child: _ErrorState(
                  onRetry: () =>
                      ref.read(internshipsProvider.notifier).fetch(),
                ),
              ),
              data: (list) => list.isEmpty
                  ? const SliverFillRemaining(child: _EmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return InternshipCard(
                            internship: item,
                            onTap: () => context.push(
                              AppRoutes.internshipDetailPath(item.id),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveSearchBar extends ConsumerWidget {
  const _SaveSearchBar({required this.filter});

  final InternshipFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showSaveDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Save this search for alerts',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final label = _buildSearchLabel(filter);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save search alert'),
        content: Text(
          'You\'ll be notified when new internships match:\n\n$label',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Save Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(savedSearchesProvider.notifier).save(
          label: label,
          keyword: filter.query.isEmpty ? null : filter.query,
          internshipType: filter.selectedTypes.length == 1
              ? filter.selectedTypes.first
              : null,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Search alert saved!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $firstName',
          style: AppTextStyles.headlineMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        Text('Find your internship', style: AppTextStyles.displayMedium),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 48, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('Could not load internships',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Check your connection and try again.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppButton(label: 'Retry', onPressed: onRetry),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('No internships found',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
