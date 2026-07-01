import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Scrollable list of matching doctor results.
class DoctorResultsList extends StatelessWidget {
  /// Creates a [DoctorResultsList].
  const DoctorResultsList({
    required this.doctors,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  /// List of matching doctor profiles.
  final List<Staff> doctors;

  /// Currently selected doctor ID.
  final String? selectedId;

  /// Callback when a doctor row is selected.
  final void Function(Staff) onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);

    if (doctors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p20,
          vertical: AppSizes.p12,
        ),
        child: Text(
          AppStrings.noDoctorsMatch,
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p20,
        vertical: AppSizes.p4,
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSizes.borderRadiusInput,
        border: Border.all(color: cs.outline, width: AppSizes.borderWidth),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: doctors.length,
        separatorBuilder: (_, __) => Divider(
          height: AppSizes.borderWidth,
          thickness: AppSizes.borderWidth,
          color: cs.outline,
        ),
        itemBuilder: (_, int i) {
          final Staff d = doctors[i];
          final bool isSelected = d.id == selectedId;

          return Material(
            color: isSelected ? cs.primaryContainer : Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p12,
                  vertical: AppSizes.p8,
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      name: d.fullName,
                      radius: AppSizes.avatarSmall / 2,
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              d.fullName,
                              style: AppTextStyles.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!d.isActive) ...[
                            const SizedBox(width: AppSizes.p6),
                            Text(
                              AppStrings.deactivated,
                              style: AppTextStyles.caption.copyWith(
                                color: clinic.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
