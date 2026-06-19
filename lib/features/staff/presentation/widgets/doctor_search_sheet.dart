import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Bottom sheet content for searching and multi-selecting doctors.
///
/// Used by [AppDoctorMultiSelectField] as the modal bottom-sheet body.
class DoctorSearchSheet extends StatefulWidget {
  const DoctorSearchSheet({
    super.key,
    required this.activeDoctors,
    required this.selectedDoctors,
    required this.onSelectionChanged,
  });

  final List<Staff> activeDoctors;
  final List<Staff> selectedDoctors;
  final void Function(List<Staff> updated) onSelectionChanged;

  @override
  State<DoctorSearchSheet> createState() => _DoctorSearchSheetState();
}

class _DoctorSearchSheetState extends State<DoctorSearchSheet> {
  String _query = '';

  List<Staff> _filtered() {
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? widget.activeDoctors
        : widget.activeDoctors
            .where((d) => d.fullName.toLowerCase().contains(q))
            .toList();
    filtered.sort(_compareDoctors);
    return filtered;
  }

  int _compareDoctors(Staff a, Staff b) {
    if (a.isActive == b.isActive) return a.fullName.compareTo(b.fullName);
    return a.isActive ? -1 : 1;
  }

  void _toggle(Staff doctor) {
    final current = List<Staff>.from(widget.selectedDoctors);
    final isSel = current.any((s) => s.id == doctor.id);
    if (isSel) {
      if (current.length <= 1) {
        AppSnackbar.show(context,
            message: 'At least one doctor is required.',
            variant: AppSnackbarVariant.error);
        return;
      }
      current.removeWhere((s) => s.id == doctor.id);
    } else {
      current.add(doctor);
    }
    widget.onSelectionChanged(current);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final filtered = _filtered();

    return Padding(
      padding: EdgeInsets.fromLTRB(0, AppSizes.p16, 0, bottom),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: AppSizes.p16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Text('Select Doctors', style: AppTextStyles.headingSmall),
        ),
        const SizedBox(height: AppSizes.p12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Search doctors…',
              hintStyle: AppTextStyles.bodySecondary,
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.primary, size: AppSizes.iconDefault),
              filled: true, fillColor: AppColors.background,
              contentPadding: AppSizes.paddingCell,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        Flexible(
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: Text(AppStrings.noMatchingDoctorsFound,
                      style: AppTextStyles.bodySecondary),
                )
              : ListView.builder(
                  shrinkWrap: true, padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final d = filtered[i];
                    final isSel =
                        widget.selectedDoctors.any((s) => s.id == d.id);
                    final initials = d.fullName.isNotEmpty
                        ? d.fullName[0].toUpperCase()
                        : '?';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(radius: 18,
                          backgroundColor: d.isActive
                              ? AppColors.primary : AppColors.textMuted,
                          child: Text(initials,
                              style: AppTextStyles.captionBold.copyWith(
                                  color: AppColors.textOnPrimary))),
                      title: Row(children: [
                        Flexible(
                          child: Text(d.fullName,
                              style: AppTextStyles.bodyMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (!d.isActive) ...[
                          const SizedBox(width: AppSizes.p6),
                          Text(AppStrings.deactivated,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ]),
                      subtitle:
                          Text(d.email, style: AppTextStyles.caption),
                      trailing: isSel
                          ? const Icon(Icons.check_circle,
                              color: AppColors.primary,
                              size: AppSizes.iconDefault)
                          : const Icon(Icons.circle_outlined,
                              color: AppColors.textMuted,
                              size: AppSizes.iconDefault),
                      onTap: () => _toggle(d),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
