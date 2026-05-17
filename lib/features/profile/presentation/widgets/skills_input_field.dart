import 'package:flutter/material.dart';
import 'package:kickr/core/constants/profile_options.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';

/// Tag-chip skill input with autocomplete suggestions.
///
/// Displays current skills as removable chips. Below them, a text field lets
/// the user type a skill name; matching suggestions appear as tappable chips.
/// Pressing Enter on the keyboard or tapping a suggestion chip adds the skill.
class SkillsInputField extends StatefulWidget {
  const SkillsInputField({
    super.key,
    required this.skills,
    required this.onAdd,
    required this.onRemove,
    this.enabled = true,
    this.label = 'Skills',
    this.hint = 'Add at least one skill',
  });

  final List<String> skills;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final bool enabled;
  final String label;
  final String hint;

  @override
  State<SkillsInputField> createState() => _SkillsInputFieldState();
}

class _SkillsInputFieldState extends State<SkillsInputField> {
  final _ctrl = TextEditingController();
  String _query = '';

  List<String> get _suggestions {
    final q = _query.toLowerCase();
    final existing = widget.skills;
    if (q.isEmpty) {
      return CommonSkills.all
          .where((s) => !existing.contains(s))
          .take(8)
          .toList();
    }
    return CommonSkills.all
        .where((s) =>
            s.toLowerCase().contains(q) && !existing.contains(s))
        .take(8)
        .toList();
  }

  void _add(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    widget.onAdd(trimmed);
    _ctrl.clear();
    setState(() => _query = '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 4),
        Text(widget.hint, style: AppTextStyles.caption),
        const SizedBox(height: 10),

        // ── Added skill chips ──────────────────────────────────────────────
        if (widget.skills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.skills
                .map((s) => _SkillChip(
                      label: s,
                      onRemove:
                          widget.enabled ? () => widget.onRemove(s) : null,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        // ── Text input ────────────────────────────────────────────────────
        TextFormField(
          controller: _ctrl,
          enabled: widget.enabled,
          textInputAction: TextInputAction.done,
          style: AppTextStyles.bodyLarge,
          onChanged: (v) => setState(() => _query = v),
          onFieldSubmitted: (_) => _add(_ctrl.text),
          decoration: InputDecoration(
            hintText: widget.skills.isEmpty
                ? 'e.g. Flutter, Python, SQL…'
                : 'Add another skill…',
            prefixIcon: const Icon(Icons.add_circle_outline_rounded,
                size: 20, color: AppColors.textSecondary),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary),
                    onPressed: () => _add(_ctrl.text),
                    tooltip: 'Add skill',
                  )
                : null,
          ),
        ),

        // ── Suggestions ───────────────────────────────────────────────────
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _query.isEmpty ? 'Popular skills:' : 'Suggestions:',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: suggestions
                .map((s) => _SuggestionChip(
                      label: s,
                      onTap: () => _add(s),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '+ $label',
          style: AppTextStyles.badge.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
