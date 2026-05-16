import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/internships/presentation/providers/internship_providers.dart';

class InternshipFilterBar extends ConsumerWidget {
  const InternshipFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(internshipFilterProvider);
    final notifier = ref.read(internshipFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: filter.selectedTypes.isEmpty,
            onTap: notifier.clearAll,
          ),
          const SizedBox(width: 8),
          ...InternshipType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: type.label,
                isSelected: filter.selectedTypes.contains(type),
                onTap: () => notifier.toggleType(type),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
