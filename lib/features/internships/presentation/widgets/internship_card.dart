import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/internships/presentation/providers/internship_providers.dart';
import 'package:kickr/features/internships/presentation/widgets/company_avatar.dart';
import 'package:kickr/features/internships/presentation/widgets/deadline_badge.dart';
import 'package:kickr/features/internships/presentation/widgets/internship_chips.dart';

class InternshipCard extends ConsumerWidget {
  const InternshipCard({
    super.key,
    required this.internship,
    this.onTap,
  });

  final Internship internship;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedInternshipIdsProvider);
    final isSaved = savedIds.valueOrNull?.contains(internship.id) ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                internship.company != null
                    ? CompanyAvatar(company: internship.company!)
                    : const _PlaceholderAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        internship.company?.name ?? 'Unknown Company',
                        style: AppTextStyles.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              internship.location,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InternshipTypeBadge(type: internship.type),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref
                      .read(savedInternshipIdsProvider.notifier)
                      .toggle(internship.id),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      size: 22,
                      color: isSaved
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(internship.title, style: AppTextStyles.headlineMedium),
            if (internship.shortDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                internship.shortDescription!,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (internship.deadline != null) ...[
              const SizedBox(height: 8),
              DeadlineBadge(deadline: internship.deadline!),
            ],
            if (internship.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              InternshipSkillChips(skills: internship.requiredSkills),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.all(Radius.circular(9)),
      ),
      child: const Icon(
        Icons.business_outlined,
        size: 22,
        color: AppColors.textSecondary,
      ),
    );
  }
}
