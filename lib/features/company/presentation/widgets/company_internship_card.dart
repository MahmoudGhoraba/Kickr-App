import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/internships/presentation/widgets/internship_chips.dart';

class CompanyInternshipCard extends StatelessWidget {
  const CompanyInternshipCard({
    super.key,
    required this.internship,
    required this.onEdit,
    required this.onArchive,
    required this.onViewApplicants,
  });

  final Internship internship;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onViewApplicants;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      internship.title,
                      style: AppTextStyles.headlineMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
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
              _StatusBadge(isActive: internship.isActive),
            ],
          ),
          if (internship.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            InternshipSkillChips(skills: internship.requiredSkills),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewApplicants,
                  icon: const Icon(Icons.people_outline_rounded, size: 16),
                  label: const Text('Applicants'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
                color: AppColors.textSecondary,
              ),
              IconButton(
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined, size: 20),
                tooltip: 'Archive',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successBg : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}
