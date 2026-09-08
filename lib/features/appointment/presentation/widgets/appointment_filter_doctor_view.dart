/// Searchable doctor picker sub-view for the appointment filter sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_doctor_tile_item.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

/// Searchable doctor picker sub-view matching the patient filter design.
class AppointmentFilterDoctorView extends StatefulWidget {
  const AppointmentFilterDoctorView({
    super.key,
    required this.selectedDoctorId,
    required this.doctors,
    required this.onDoctorSelected,
    required this.onBack,
  });

  final String? selectedDoctorId;
  final List<Staff> doctors;
  final ValueChanged<String?> onDoctorSelected;
  final VoidCallback onBack;

  @override
  State<AppointmentFilterDoctorView> createState() =>
      _AppointmentFilterDoctorViewState();
}

class _AppointmentFilterDoctorViewState
    extends State<AppointmentFilterDoctorView> {
  String _searchQuery = '';

  List<Staff> get _filteredDoctors {
    if (_searchQuery.isEmpty) return widget.doctors;
    final q = _searchQuery.toLowerCase();
    return widget.doctors
        .where((d) => d.fullName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doctors = _filteredDoctors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(cs),
        _buildSearchField(cs),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p8,
            ),
            itemCount: doctors.length + 1,
            separatorBuilder: (_, __) => Divider(
              height: AppSizes.borderWidth,
              thickness: AppSizes.borderWidth,
              color: cs.outlineVariant.withAlpha(80),
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return AppointmentFilterDoctorTileItem(
                  title: AppStrings.filterAllDoctors,
                  isSelected: widget.selectedDoctorId == null,
                  onTap: () => widget.onDoctorSelected(null),
                  isAll: true,
                );
              }
              final doc = doctors[index - 1];
              return AppointmentFilterDoctorTileItem(
                title: doc.fullName,
                isInactive: !doc.isActive,
                isSelected: widget.selectedDoctorId == doc.id,
                onTap: () => widget.onDoctorSelected(doc.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p12,
        AppSizes.p12,
        AppSizes.p16,
        AppSizes.p8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(LucideIcons.chevron_left, size: 18),
            label: Text(
              AppStrings.filtersButton,
              style: AppTextStyles.bodyBold.copyWith(color: cs.primary),
            ),
          ),
          Text(
            AppStrings.assignedDoctors,
            style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface),
          ),
          TextButton(
            onPressed: widget.onBack,
            child: Text(
              AppStrings.actionDone,
              style: AppTextStyles.bodyBold.copyWith(color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p4,
        AppSizes.p16,
        AppSizes.p8,
      ),
      child: Container(
        height: 40.0,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(AppSizes.r8),
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: AppTextStyles.body.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: AppStrings.searchDoctorsHint,
            hintStyle: AppTextStyles.caption.copyWith(
              color: cs.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              LucideIcons.search,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p12,
              vertical: AppSizes.p8,
            ),
          ),
        ),
      ),
    );
  }
}
