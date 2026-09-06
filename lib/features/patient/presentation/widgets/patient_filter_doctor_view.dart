import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

/// Searchable doctor picker sub-view for the patient filter sheet.
class PatientFilterDoctorView extends StatefulWidget {
  const PatientFilterDoctorView({
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
  State<PatientFilterDoctorView> createState() => _PatientFilterDoctorViewState();
}

class _PatientFilterDoctorViewState extends State<PatientFilterDoctorView> {
  String _searchQuery = '';

  List<Staff> get _filteredDoctors {
    if (_searchQuery.isEmpty) return widget.doctors;
    final q = _searchQuery.toLowerCase();
    return widget.doctors.where((d) => d.fullName.toLowerCase().contains(q)).toList();
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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
            itemCount: doctors.length + 1,
            separatorBuilder: (_, __) => Divider(
              height: AppSizes.borderWidth,
              thickness: AppSizes.borderWidth,
              color: cs.outlineVariant.withAlpha(80),
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildDoctorTile(
                  cs: cs,
                  title: AppStrings.filterAllDoctors,
                  isSelected: widget.selectedDoctorId == null,
                  onTap: () => widget.onDoctorSelected(null),
                  isAllOption: true,
                );
              }
              final doc = doctors[index - 1];
              return _buildDoctorTile(
                cs: cs,
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
      padding: const EdgeInsets.fromLTRB(AppSizes.p12, AppSizes.p12, AppSizes.p16, AppSizes.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(LucideIcons.chevron_left, size: 18),
            label: Text(AppStrings.filtersButton, style: AppTextStyles.bodyBold.copyWith(color: cs.primary)),
          ),
          Text(AppStrings.assignedDoctors, style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface)),
          TextButton(
            onPressed: widget.onBack,
            child: Text('Done', style: AppTextStyles.bodyBold.copyWith(color: cs.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p4, AppSizes.p16, AppSizes.p8),
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
            hintText: 'Search doctors\u2026',
            hintStyle: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
            prefixIcon: Icon(LucideIcons.search, size: 16, color: cs.onSurfaceVariant),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorTile({
    required ColorScheme cs,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isAllOption = false,
    bool isInactive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p8, horizontal: AppSizes.p8),
        child: Row(
          children: [
            if (!isAllOption) ...[
              PatientMonogramBadge(name: title, size: 28.0),
              const SizedBox(width: AppSizes.p10),
            ] else ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.users, size: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: AppSizes.p10),
            ],
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isInactive) ...[
                    const SizedBox(width: AppSizes.p6),
                    Text('(Inactive)', style: AppTextStyles.caption.copyWith(color: cs.error)),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
