import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, outline, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label, style: _labelStyle),
            ],
          );

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: Text(label, style: AppTextStyles.labelMedium),
        ),
      AppButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: Text(label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.primary)),
        ),
    };
  }

  TextStyle get _labelStyle => variant == AppButtonVariant.primary
      ? AppTextStyles.labelLarge
      : AppTextStyles.labelMedium.copyWith(color: AppColors.primary);
}
