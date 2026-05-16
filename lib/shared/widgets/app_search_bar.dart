import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search',
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        suffixIcon: controller != null
            ? ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!,
                builder: (_, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      controller!.clear();
                      onChanged('');
                    },
                  );
                },
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 2),
        ),
      ),
    );
  }
}
