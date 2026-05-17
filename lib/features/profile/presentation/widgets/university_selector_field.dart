import 'package:flutter/material.dart';
import 'package:kickr/core/constants/profile_options.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';

/// Tappable field that opens a searchable bottom-sheet selector for Egyptian
/// universities. Typing a custom name (not in the list) surfaces an
/// "Use '[query]'" option for free-text entry.
class UniversitySelectorField extends StatelessWidget {
  const UniversitySelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.label = 'University',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String label;

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UniversitySheet(
        current: value,
        onSelect: (u) {
          Navigator.of(context).pop();
          onChanged(u);
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
                Icon(Icons.school_outlined,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Select your university' : value,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: value.isEmpty
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

class _UniversitySheet extends StatefulWidget {
  const _UniversitySheet({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  @override
  State<_UniversitySheet> createState() => _UniversitySheetState();
}

class _UniversitySheetState extends State<_UniversitySheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = EgyptianUniversities.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? EgyptianUniversities.all
          : EgyptianUniversities.all
              .where((u) => u.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _showCustomOption =>
      _query.isNotEmpty &&
      !_filtered.any((u) => u.toLowerCase() == _query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select University', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _searchCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Search or type university name…',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: bottomInset + 16),
              children: [
                if (_showCustomOption)
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary),
                    title: Text(
                      'Use "$_query"',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.primary),
                    ),
                    onTap: () => widget.onSelect(_query),
                  ),
                ..._filtered.map(
                  (u) => ListTile(
                    leading: Icon(
                      Icons.school_outlined,
                      size: 20,
                      color: widget.current == u
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    title: Text(u, style: AppTextStyles.bodyLarge),
                    trailing: widget.current == u
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () => widget.onSelect(u),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
