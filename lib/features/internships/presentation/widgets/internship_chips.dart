import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/features/internships/data/internship_model.dart';

/// Colored badge displaying the internship location type.
class InternshipTypeBadge extends StatelessWidget {
  const InternshipTypeBadge({super.key, required this.type});

  final InternshipType type;

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor) = switch (type) {
      InternshipType.remote => (AppColors.typeRemoteText, AppColors.typeRemoteBg),
      InternshipType.hybrid => (AppColors.info,           AppColors.infoBg),
      InternshipType.onsite => (AppColors.typeOnsiteText, AppColors.typeOnsiteBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Single skill chip used in card and detail views.
class InternshipSkillChip extends StatelessWidget {
  const InternshipSkillChip({
    super.key,
    required this.label,
    this.isExtra = false,
  });

  final String label;
  final bool isExtra;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExtra ? AppColors.surfaceVariant : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isExtra ? AppColors.border : AppColors.primary.withAlpha(50),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isExtra ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
    );
  }
}

/// Renders up to [maxVisible] skill chips with an overflow "+N more" chip.
class InternshipSkillChips extends StatelessWidget {
  const InternshipSkillChips({
    super.key,
    required this.skills,
    this.maxVisible = 3,
  });

  final List<String> skills;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = skills.take(maxVisible).toList();
    final extra = skills.length - maxVisible;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...visible.map((s) => InternshipSkillChip(label: s)),
        if (extra > 0) InternshipSkillChip(label: '+$extra more', isExtra: true),
      ],
    );
  }
}
