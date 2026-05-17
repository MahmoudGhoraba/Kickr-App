import 'package:flutter/material.dart';
import 'package:kickr/core/constants/profile_options.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';

/// Text field with inline autocomplete suggestions for common majors.
/// Allows fully custom input — suggestions are advisory, not restrictive.
class MajorSelectorField extends StatefulWidget {
  const MajorSelectorField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Major',
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String label;

  @override
  State<MajorSelectorField> createState() => _MajorSelectorFieldState();
}

class _MajorSelectorFieldState extends State<MajorSelectorField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(MajorSelectorField old) {
    super.didUpdateWidget(old);
    // Re-initialise when the parent seeds a new value (e.g. profile loaded).
    if (old.initialValue != widget.initialValue &&
        _ctrl.text != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      setState(() => _showSuggestions = false);
    }
  }

  List<String> get _suggestions {
    final q = _ctrl.text.toLowerCase();
    if (q.isEmpty) return const [];
    return CommonMajors.all
        .where((m) => m.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  void _selectSuggestion(String major) {
    _ctrl.text = major;
    _ctrl.selection = TextSelection.collapsed(offset: major.length);
    _focus.unfocus();
    setState(() => _showSuggestions = false);
    widget.onChanged(major);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ctrl,
          focusNode: _focus,
          enabled: widget.enabled,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.bodyLarge,
          onChanged: (v) {
            setState(() => _showSuggestions = v.isNotEmpty);
            widget.onChanged(v);
          },
          decoration: const InputDecoration(
            hintText: 'e.g. Computer Science',
            prefixIcon: Icon(Icons.auto_stories_outlined,
                size: 20, color: AppColors.textSecondary),
          ),
        ),
        if (_showSuggestions && suggestions.isNotEmpty)
          _SuggestionsBox(
            suggestions: suggestions,
            onSelect: _selectSuggestion,
          ),
      ],
    );
  }
}

class _SuggestionsBox extends StatelessWidget {
  const _SuggestionsBox({required this.suggestions, required this.onSelect});

  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: suggestions.asMap().entries.map((entry) {
          final isLast = entry.key == suggestions.length - 1;
          return InkWell(
            onTap: () => onSelect(entry.value),
            borderRadius: BorderRadius.vertical(
              top: entry.key == 0 ? const Radius.circular(10) : Radius.zero,
              bottom: isLast ? const Radius.circular(10) : Radius.zero,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Text(entry.value, style: AppTextStyles.bodyLarge),
            ),
          );
        }).toList(),
      ),
    );
  }
}
