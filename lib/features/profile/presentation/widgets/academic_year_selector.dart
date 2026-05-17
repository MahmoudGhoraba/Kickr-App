import 'package:flutter/material.dart';
import 'package:kickr/core/constants/profile_options.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';

/// Tappable field that opens a bottom-sheet list for selecting academic year.
class AcademicYearSelector extends StatelessWidget {
  const AcademicYearSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Academic Year',
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String label;

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AcademicYearSheet(
        current: value,
        onSelect: (year) {
          Navigator.of(context).pop();
          onChanged(year);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? () => _open(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: enabled ? AppColors.surface : AppColors.surfaceVariant,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? 'Select your academic year',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: value == null
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AcademicYearSheet extends StatelessWidget {
  const _AcademicYearSheet({required this.current, required this.onSelect});

  final String? current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Academic Year', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: AcademicYears.all.map(
                  (year) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(year, style: AppTextStyles.bodyLarge),
                    trailing: current == year
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () => onSelect(year),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
