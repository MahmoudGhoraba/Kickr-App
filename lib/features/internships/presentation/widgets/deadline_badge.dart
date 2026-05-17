import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';

/// Compact badge showing application deadline status.
class DeadlineBadge extends StatelessWidget {
  const DeadlineBadge({super.key, required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = deadline.isBefore(now);
    final daysLeft = deadline.difference(now).inDays;
    final isUrgent = !isExpired && daysLeft <= 3;

    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String label;

    if (isExpired) {
      bgColor = AppColors.errorBg;
      textColor = AppColors.error;
      icon = Icons.event_busy_rounded;
      label = 'Expired';
    } else if (isUrgent) {
      bgColor = AppColors.warningBg;
      textColor = AppColors.warning;
      icon = Icons.schedule_rounded;
      label = daysLeft == 0 ? 'Last day' : '$daysLeft day${daysLeft == 1 ? '' : 's'} left';
    } else {
      bgColor = AppColors.infoBg;
      textColor = AppColors.info;
      icon = Icons.event_rounded;
      label = _formatDate(deadline);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
