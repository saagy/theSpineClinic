import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/form_section.dart';

const _t = AppStrings.invoices;

/// Remove for an offered service, Restore for a removed one. One plain
/// action replaces the old on/off switch so staff never meet "archived".
class ServiceAvailabilitySection extends StatelessWidget {
  const ServiceAvailabilitySection({
    super.key,
    required this.active,
    required this.enabled,
    required this.onRemove,
    required this.onRestore,
  });
  final bool active;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const Size minimum = Size(AppSizes.tappableMin, AppSizes.tappableMin);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8));
    return FormSection(
      title: _t.sectionAvailability,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active ? _t.removeHelp : _t.removedHelp,
            style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.p12),
          active
              ? OutlinedButton.icon(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline, size: AppSizes.iconSmall),
                  label: Text(_t.removeService, style: AppTextStyles.bodyMedium),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                    minimumSize: minimum,
                    shape: shape,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: enabled ? onRestore : null,
                  icon: const Icon(Icons.restore, size: AppSizes.iconSmall),
                  label: Text(_t.restoreService, style: AppTextStyles.bodyMedium),
                  style: OutlinedButton.styleFrom(minimumSize: minimum, shape: shape),
                ),
        ],
      ),
    );
  }
}
