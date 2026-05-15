import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = LogoSize.medium});

  final LogoSize size;

  @override
  Widget build(BuildContext context) {
    final iconSize = switch (size) {
      LogoSize.small => 32.0,
      LogoSize.medium => 48.0,
      LogoSize.large => 64.0,
    };

    final textStyle = switch (size) {
      LogoSize.small => AppTextStyles.headlineMedium,
      LogoSize.medium => AppTextStyles.headlineLarge,
      LogoSize.large => AppTextStyles.displayMedium,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(iconSize * 0.25),
          ),
          child: Center(
            child: Text(
              'K',
              style: textStyle.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Kickr',
          style: textStyle.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

enum LogoSize { small, medium, large }
