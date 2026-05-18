import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/admin/data/verification_review_entry.dart';
import 'package:kickr/features/admin/presentation/providers/admin_providers.dart';
import 'package:kickr/features/admin/presentation/widgets/verification_review_card.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final Set<String> _actingIds = {};

  Future<void> _approve(String userId) async {
    setState(() => _actingIds.add(userId));
    try {
      await ref.read(verificationsProvider.notifier).approve(userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actingIds.remove(userId));
    }
  }

  Future<void> _reject(String userId) async {
    setState(() => _actingIds.add(userId));
    try {
      await ref.read(verificationsProvider.notifier).reject(userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actingIds.remove(userId));
    }
  }

  Future<void> _viewId(VerificationReviewEntry entry) async {
    final storagePath = entry.studentIdUrl;
    if (storagePath == null || storagePath.isEmpty) return;
    try {
      final url = await ref
          .read(adminRepositoryProvider)
          .getStudentIdSignedUrl(storagePath);
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.isAbsolute) return;
      final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredVerificationsProvider);
    final pendingCount = ref.watch(pendingCountProvider);
    final activeFilter = ref.watch(adminVerificationFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        title: Text('Verifications', style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(verificationsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            active: activeFilter,
            pendingCount: pendingCount,
            onSelect: (status) => ref
                .read(adminVerificationFilterProvider.notifier)
                .state = status,
          ),
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _ErrorState(
                message: e.toString(),
                onRetry: () =>
                    ref.read(verificationsProvider.notifier).refresh(),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return _EmptyState(filter: activeFilter);
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(verificationsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      return VerificationReviewCard(
                        entry: entry,
                        isActing: _actingIds.contains(entry.userId),
                        onApprove: () => _approve(entry.userId),
                        onReject: () => _reject(entry.userId),
                        onViewId: () => _viewId(entry),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.active,
    required this.pendingCount,
    required this.onSelect,
  });

  final VerificationStatus? active;
  final int pendingCount;
  final ValueChanged<VerificationStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: pendingCount > 0
                  ? 'Pending ($pendingCount)'
                  : 'Pending',
              selected: active == VerificationStatus.pending,
              onTap: () => onSelect(VerificationStatus.pending),
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Verified',
              selected: active == VerificationStatus.verified,
              onTap: () => onSelect(VerificationStatus.verified),
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Unverified',
              selected: active == VerificationStatus.unverified,
              onTap: () => onSelect(VerificationStatus.unverified),
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'All',
              selected: active == null,
              onTap: () => onSelect(null),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.badge.copyWith(
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final VerificationStatus? filter;

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (filter) {
      VerificationStatus.pending => (
          Icons.check_circle_outline_rounded,
          'No pending verifications.\nAll caught up!',
        ),
      VerificationStatus.verified => (
          Icons.verified_outlined,
          'No verified students yet.',
        ),
      VerificationStatus.unverified => (
          Icons.person_outline_rounded,
          'No unverified students.',
        ),
      null => (Icons.group_outlined, 'No students found.'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
