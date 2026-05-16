import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/features/applications/data/application_model.dart';

class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor) = switch (status) {
      ApplicationStatus.pending  => (AppColors.warning,  AppColors.warningBg),
      ApplicationStatus.reviewed => (AppColors.info,     AppColors.infoBg),
      ApplicationStatus.accepted => (AppColors.success,  AppColors.successBg),
      ApplicationStatus.rejected => (AppColors.error,    AppColors.errorBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
