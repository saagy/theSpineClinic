import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/form_section.dart';
import 'invoice_form_input.dart';
import 'invoice_line_editor.dart';

const _t = AppStrings.invoices;

/// The invoice's service lines with an Add service action below them.
class InvoiceLinesSection extends StatelessWidget {
  const InvoiceLinesSection({
    super.key,
    required this.input,
    required this.enabled,
    required this.showMissing,
    required this.onChanged,
    required this.onAdd,
  });
  final InvoiceFormInput input;
  final bool enabled;
  final bool showMissing;
  final ValueChanged<VoidCallback> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FormSection(
      title: _t.columnServices,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, line) in input.lines.indexed) ...[
            if (index > 0) Divider(height: AppSizes.borderWidth, color: colors.outlineVariant),
            InvoiceLineEditor(
              key: ValueKey(line.key),
              line: line,
              enabled: enabled,
              onChanged: onChanged,
              onRemove: () => onChanged(() => input.lines.remove(line)),
            ),
          ],
          if (input.lines.isEmpty && showMissing)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.p12),
              child: Text(
                _t.linesRequired,
                style: AppTextStyles.caption.copyWith(color: colors.error),
              ),
            ),
          if (input.lines.isNotEmpty) const SizedBox(height: AppSizes.p8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add, size: AppSizes.iconSmall),
              label: Text(_t.addLine, style: AppTextStyles.bodyBold),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
