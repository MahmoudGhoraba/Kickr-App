import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/core/router/app_router.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/internships/presentation/providers/internship_providers.dart';
import 'package:kickr/features/internships/presentation/widgets/deadline_badge.dart';
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
    final internships = ref.watch(personalizedFeedProvider);
    final filter = ref.watch(internshipFilterProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final firstName = _firstName(profile?.fullName);

    final closingSoon =
        ref.watch(closingSoonProvider).valueOrNull ?? const [];
    final isPersonalized =
        profile != null && profile.hasPersonalizationData;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(internshipsProvider.notifier).fetch(),
        child: CustomScrollView(
          slivers: [
            // ── Header: greeting + search + filter ──────────────────────────
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
                      onChanged: (q) => ref
                          .read(internshipFilterProvider.notifier)
                          .setQuery(q),
                    ),
                    const SizedBox(height: 12),
                    const InternshipFilterBar(),
                    if (!filter.isEmpty) ...[
                      const SizedBox(height: 8),
                      _SaveSearchBar(filter: filter),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // ── Closing soon carousel (shown only when there are matches) ──
            if (closingSoon.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: _SectionHeader(
                  'Closing Soon',
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.warning,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    itemCount: closingSoon.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = closingSoon[index];
                      return _ClosingSoonCard(
                        internship: item,
                        onTap: () => context.push(
                          AppRoutes.internshipDetailPath(item.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // ── Main feed section header ─────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                isPersonalized ? 'For You' : 'All Internships',
                icon: isPersonalized
                    ? Icons.auto_awesome_rounded
                    : Icons.work_outline_rounded,
                iconColor:
                    isPersonalized ? AppColors.primary : AppColors.textSecondary,
              ),
            ),

            // ── Main feed list ───────────────────────────────────────────
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

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
    this.title, {
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(title, style: AppTextStyles.headlineMedium),
        ],
      ),
    );
  }
}

// ─── Closing soon compact card ────────────────────────────────────────────────

class _ClosingSoonCard extends StatelessWidget {
  const _ClosingSoonCard({
    required this.internship,
    required this.onTap,
  });

  final Internship internship;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(14)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DeadlineBadge(deadline: internship.deadline!),
            const SizedBox(height: 8),
            Text(
              internship.title,
              style: AppTextStyles.labelMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              internship.company?.name ?? '',
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Save search bar ─────────────────────────────────────────────────────────

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

// ─── Greeting ─────────────────────────────────────────────────────────────────

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

// ─── Loading / error / empty states ──────────────────────────────────────────

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
