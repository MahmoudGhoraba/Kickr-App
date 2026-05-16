import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/features/internships/data/company_model.dart';

class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({super.key, required this.company, this.size = 44});

  final Company company;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: company.logoUrl != null
          ? Image.network(
              company.logoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _InitialsView(company: company, size: size),
            )
          : _InitialsView(company: company, size: size),
    );
  }
}

class _InitialsView extends StatelessWidget {
  const _InitialsView({required this.company, required this.size});

  final Company company;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: _colorFor(company.name),
      child: Center(
        child: Text(
          _initials(company.name),
          style: TextStyle(
            color: AppColors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? 'C' : name[0].toUpperCase();
  }

  Color _colorFor(String name) {
    const palette = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF3B82F6),
      Color(0xFFEF4444),
    ];
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }
}
