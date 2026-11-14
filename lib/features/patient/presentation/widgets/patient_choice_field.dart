import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../../../shared/widgets/record_menu_select.dart';

const String _other = '\u0000other';

/// A text detail chosen from common answers, so staff rarely need to type.
/// "Other" opens a text field; a saved answer outside the list shows there.
class PatientChoiceField extends StatefulWidget {
  const PatientChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.choices,
    required this.icon,
    required this.onChanged,
    required this.enabled,
  });
  final String label;
  final String? value;
  final List<String> choices;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  State<PatientChoiceField> createState() => _PatientChoiceFieldState();
}

class _PatientChoiceFieldState extends State<PatientChoiceField> {
  late bool _typing = widget.value != null && !widget.choices.contains(widget.value);

  void _select(String? choice) {
    setState(() => _typing = choice == _other);
    widget.onChanged(choice == _other ? null : choice);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      RecordMenuSelect<String?>(
        label: widget.label,
        value: _typing ? _other : widget.value,
        isField: true,
        options: [
          const RecordMenuAction(null, AppStrings.patientNotSpecified, Icons.remove),
          for (final choice in widget.choices) RecordMenuAction(choice, choice, widget.icon),
          const RecordMenuAction(
            _other,
            AppStrings.patientChoiceOther,
            Icons.edit_outlined,
            dividerBefore: true,
          ),
        ],
        onChanged: widget.enabled ? _select : null,
      ),
      if (_typing) ...[
        const SizedBox(height: AppSizes.p8),
        TextFormField(
          initialValue: widget.value,
          enabled: widget.enabled,
          autofocus: widget.value == null,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.body,
          decoration: InputDecoration(labelText: AppStrings.patientChoiceOtherLabel(widget.label)),
          onChanged: (text) => widget.onChanged(text.trim().isEmpty ? null : text.trim()),
        ),
      ],
    ],
  );
}
