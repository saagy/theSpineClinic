import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_filter_tile.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';
import 'package:spine_clinic_app/shared/widgets/responsive_button_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';

/// A unified bottom sheet layout for filtering data, satisfying Rule 17.
class UnifiedFilterSheet extends ConsumerStatefulWidget {
  const UnifiedFilterSheet({
    required this.initialDoctorId,
    required this.initialClinic,
    required this.onApplied,
    this.showDoctorFilter = true,
    this.showBranchFilter = true,
    this.onReset,
    this.additionalFilters = const [],
    this.scrollController,
    this.showActions = true,
    this.showDeactivated = true,
    this.excludeDoctorIds,
    super.key,
  });

  final bool showDoctorFilter;
  final String? initialDoctorId;
  final ClinicLocation? initialClinic;
  final void Function(String? doctorId, ClinicLocation? clinic) onApplied;
  final bool showBranchFilter;
  final VoidCallback? onReset;
  final List<Widget> additionalFilters;
  final ScrollController? scrollController;
  final bool showActions;
  final bool showDeactivated;
  final List<String>? excludeDoctorIds;

  @override
  ConsumerState<UnifiedFilterSheet> createState() => _UnifiedFilterSheetState();
}

class _UnifiedFilterSheetState extends ConsumerState<UnifiedFilterSheet> {
  String? _selectedDoctorId;
  ClinicLocation? _clinic;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.initialDoctorId;
    _clinic = widget.initialClinic;
  }

  Future<void> _pickDoctor(BuildContext context) async {
    final picked = await DoctorPickerSheet.showSingle(
      context: context,
      selectedDoctorId: _selectedDoctorId,
      showAllOption: true,
      showDeactivated: widget.showDeactivated,
      excludeDoctorIds: widget.excludeDoctorIds,
    );
    // If popped or picked, update doctor. If null, it means "All Doctors".
    setState(() {
      _selectedDoctorId = picked?.id;
    });
    if (!widget.showActions) {
      widget.onApplied(_selectedDoctorId, _clinic);
    }
  }

  void _clearDoctor() {
    setState(() => _selectedDoctorId = null);
  }

  void _clearAll() {
    setState(() {
      if (widget.showDoctorFilter) _selectedDoctorId = null;
      if (widget.showBranchFilter) _clinic = null;
    });
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = widget.showDeactivated
        ? ref.watch(allDoctorsForFilterProvider)
        : ref.watch(activeDoctorsProvider);

    Staff? selectedDoctor;
    if (_selectedDoctorId != null && doctorsAsync.hasValue) {
      selectedDoctor = doctorsAsync.value!
          .where((d) => d.id == _selectedDoctorId)
          .firstOrNull;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showDoctorFilter) ...[
                  const SectionHeader(title: AppStrings.filterByDoctor),
                  const SizedBox(height: AppSizes.p8),
                  DoctorFilterTile(
                    selectedDoctor: selectedDoctor,
                    onTap: () => _pickDoctor(context),
                    onClear: _selectedDoctorId != null ? _clearDoctor : null,
                  ),
                ],
                if (widget.showBranchFilter) ...[
                  const SizedBox(height: AppSizes.p16),
                  const SectionHeader(title: AppStrings.filterByBranch),
                  const SizedBox(height: AppSizes.p8),
                  Wrap(
                    spacing: AppSizes.p8,
                    runSpacing: AppSizes.p8,
                    children: [
                      AppFilterChip(
                        label: AppStrings.allBranches,
                        isActive: _clinic == null,
                        onTap: () => setState(() => _clinic = null),
                      ),
                      AppFilterChip(
                        label: AppStrings.clinicTagamoa,
                        isActive: _clinic == ClinicLocation.tagamoa,
                        onTap: () => setState(() => _clinic = ClinicLocation.tagamoa),
                      ),
                      AppFilterChip(
                        label: AppStrings.clinicMasrElgedida,
                        isActive: _clinic == ClinicLocation.masrElgedida,
                        onTap: () => setState(() => _clinic = ClinicLocation.masrElgedida),
                      ),
                    ],
                  ),
                ],
                if (widget.additionalFilters.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.p16),
                  ...widget.additionalFilters,
                ],
              ],
            ),
          ),
        ),
        if (widget.showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p20,
              AppSizes.p8,
              AppSizes.p20,
              AppSizes.p16,
            ),
            child: ResponsiveButtonRow(
              children: [
                AppButton(
                  labelText: 'Reset',
                  onPressed: _clearAll,
                  variant: AppButtonVariant.secondary,
                  shape: AppButtonShape.pill,
                ),
                AppButton(
                  labelText: AppStrings.applyFilters,
                  onPressed: () => widget.onApplied(_selectedDoctorId, _clinic),
                  shape: AppButtonShape.pill,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
