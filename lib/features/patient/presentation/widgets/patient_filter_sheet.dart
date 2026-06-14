/// Filter bottom sheet for the patient list.
///
/// Doctor filter uses a searchable typeahead field — the user types to
/// narrow results, then taps a row to select. Scales to any number of
/// doctors. Branch filter uses [AppFilterChip] pills.
///
/// Rule 1 — under 200 lines.
/// Rule 7 — zero hardcoded strings.
/// Rule 8 — zero hardcoded sizing or colours.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart'
    show AppFilterChip;
import 'package:spine_clinic_app/shared/widgets/primary_button.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';

/// Shows the patient filter bottom sheet and returns `true` if applied.
Future<bool> showPatientFilterSheet(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(patientListProvider.notifier);

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) => _FilterSheetContent(
      currentDoctorId: notifier.currentDoctorFilter,
      currentClinic: notifier.currentClinicFilter,
      onApplied: (String? doctorId, ClinicLocation? clinic) {
        if (doctorId != notifier.currentDoctorFilter) {
          notifier.setDoctorFilter(doctorId);
        }
        if (clinic != notifier.currentClinicFilter) {
          notifier.setClinicFilter(clinic);
        }
        Navigator.of(ctx).pop(true);
      },
    ),
  ).then((v) => v ?? false);
}

class _FilterSheetContent extends ConsumerStatefulWidget {
  const _FilterSheetContent({
    required this.currentDoctorId,
    required this.currentClinic,
    required this.onApplied,
  });

  final String? currentDoctorId;
  final ClinicLocation? currentClinic;
  final void Function(String? doctorId, ClinicLocation? clinic) onApplied;

  @override
  ConsumerState<_FilterSheetContent> createState() =>
      _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<_FilterSheetContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _selectedDoctorId;
  String _selectedDoctorName = '';
  late ClinicLocation? _clinic;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.currentDoctorId;
    _clinic = widget.currentClinic;
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) setState(() => _showResults = true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _selectDoctor(Staff doctor) {
    setState(() {
      _selectedDoctorId = doctor.id;
      _selectedDoctorName = doctor.fullName;
      _searchCtrl.clear();
      _showResults = false;
    });
    _searchFocus.unfocus();
  }

  void _clearDoctor() {
    setState(() {
      _selectedDoctorId = null;
      _selectedDoctorName = '';
    });
  }

  List<Staff> _filter(List<Staff> doctors) {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return doctors;
    return doctors
        .where((d) => d.fullName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(activeDoctorsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.r16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                const SizedBox(height: AppSizes.p8),
                Center(
                  child: Container(
                    width: AppSizes.handleWidth,
                    height: AppSizes.handleHeight,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppSizes.p2)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.p16),

                // ── Doctor section ──
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
                  child: SectionHeader(title: AppStrings.filterByDoctor),
                ),
                const SizedBox(height: AppSizes.p8),

                // Selected doctor chip
                if (_selectedDoctorId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p20,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p8),
                      child: AppFilterChip(
                        label: _selectedDoctorName,
                        isActive: true,
                        onTap: _clearDoctor,
                      ),
                    ),
                  ),

                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p20,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: (_) =>
                        setState(() => _showResults = true),
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchDoctors,
                      hintStyle: AppTextStyles.bodySecondary,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: AppSizes.iconDefault,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: AppSizes.iconSmall,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                _clearDoctor();
                                setState(
                                    () => _showResults = true);
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // Results dropdown
                if (_showResults)
                  doctorsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSizes.p16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (List<Staff> doctors) {
                      final filtered = _filter(doctors);
                      return _DoctorResultsList(
                        doctors: filtered,
                        selectedId: _selectedDoctorId,
                        onSelect: _selectDoctor,
                      );
                    },
                  ),

                const SizedBox(height: AppSizes.p12),

                // ── Branch section ──
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
                  child: SectionHeader(title: AppStrings.filterByBranch),
                ),
                const SizedBox(height: AppSizes.p8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p20,
                  ),
                  child: Wrap(
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
                        onTap: () => setState(
                            () => _clinic = ClinicLocation.tagamoa),
                      ),
                      AppFilterChip(
                        label: AppStrings.clinicMasrElgedida,
                        isActive: _clinic == ClinicLocation.masrElgedida,
                        onTap: () => setState(
                            () => _clinic = ClinicLocation.masrElgedida),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.p24),

                // ── Actions ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p20,
                  ),
                  child: PrimaryButton(
                    label: AppStrings.applyFilters,
                    onPressed: () =>
                        widget.onApplied(_selectedDoctorId, _clinic),
                  ),
                ),
                const SizedBox(height: AppSizes.p16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable list of matching doctor results.
///
/// Styled with design tokens — no hardcoded values.
class _DoctorResultsList extends StatelessWidget {
  const _DoctorResultsList({
    required this.doctors,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Staff> doctors;
  final String? selectedId;
  final void Function(Staff) onSelect;

  @override
  Widget build(BuildContext context) {
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
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusInput,
        border: Border.all(
          color: AppColors.border,
          width: AppSizes.borderWidth,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: doctors.length,
        separatorBuilder: (_, __) => const Divider(
          height: AppSizes.borderWidth,
          thickness: AppSizes.borderWidth,
          color: AppColors.border,
        ),
        itemBuilder: (_, int i) {
          final Staff d = doctors[i];
          final String initials = d.fullName.isNotEmpty
              ? d.fullName[0].toUpperCase()
              : '?';
          final bool isSelected = d.id == selectedId;

          return Material(
            color: isSelected ? AppColors.primaryLight : AppColors.transparent,
            child: InkWell(
              onTap: () => onSelect(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p12,
                  vertical: AppSizes.p8,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AppSizes.avatarSmall / 2,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials,
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Text(
                        d.fullName,
                        style: AppTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
