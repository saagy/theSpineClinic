import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_results_list.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';
import 'package:spine_clinic_app/shared/widgets/primary_button.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';

/// A unified bottom sheet layout for filtering data, satisfying Rule 17.
class UnifiedFilterSheet extends ConsumerStatefulWidget {
  /// Creates a [UnifiedFilterSheet].
  const UnifiedFilterSheet({
    required this.initialDoctorId,
    required this.initialClinic,
    required this.onApplied,
    this.showDoctorFilter = true,
    this.showBranchFilter = true,
    this.onReset,
    this.additionalFilters = const [],
    this.scrollController,
    super.key,
  });

  /// Whether to show the doctor filter section (defaults to true).
  final bool showDoctorFilter;

  /// The initially selected doctor's ID.
  final String? initialDoctorId;

  /// The initially selected clinic location.
  final ClinicLocation? initialClinic;

  /// Callback when filters are applied.
  final void Function(String? doctorId, ClinicLocation? clinic) onApplied;

  /// Whether to show the branch filter option (defaults to true).
  final bool showBranchFilter;

  /// Callback when filters are reset.
  final VoidCallback? onReset;

  /// Optional composable widgets to inject below the doctor and branch filters.
  final List<Widget> additionalFilters;

  /// Scroll controller passed down from DraggableScrollableSheet container.
  final ScrollController? scrollController;

  @override
  ConsumerState<UnifiedFilterSheet> createState() => _UnifiedFilterSheetState();
}

class _UnifiedFilterSheetState extends ConsumerState<UnifiedFilterSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _selectedDoctorId;
  String _selectedDoctorName = '';
  ClinicLocation? _clinic;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.initialDoctorId;
    _clinic = widget.initialClinic;
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        setState(() => _showResults = true);
      }
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
      _selectedDoctorName = doctor.isActive
          ? doctor.fullName
          : '${doctor.fullName} (${AppStrings.inactive})';
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

  void _clearAll() {
    setState(() {
      if (widget.showDoctorFilter) {
        _selectedDoctorId = null;
        _selectedDoctorName = '';
      }
      if (widget.showBranchFilter) {
        _clinic = null;
      }
    });
    if (widget.onReset != null) {
      widget.onReset!();
    }
  }

  List<Staff> _filter(List<Staff> doctors) {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return doctors;
    return doctors.where((d) => d.fullName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(allDoctorsForFilterProvider);

    // Resolve initial doctor name when loaded.
    if (_selectedDoctorId != null && _selectedDoctorName.isEmpty) {
      final doctors = doctorsAsync.value;
      if (doctors != null) {
        final matches = doctors.where((d) => d.id == _selectedDoctorId);
        if (matches.isNotEmpty) {
          _selectedDoctorName = matches.first.fullName;
        }
      }
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
                  // ── Doctor section ──
                  const SectionHeader(title: AppStrings.filterByDoctor),
                  const SizedBox(height: AppSizes.p8),

                  // Selected doctor chip
                  if (_selectedDoctorId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppFilterChip(
                          label: _selectedDoctorName.isNotEmpty
                              ? _selectedDoctorName
                              : 'Loading doctor...',
                          isActive: true,
                          onTap: _clearDoctor,
                        ),
                      ),
                    ),

                  // Search field
                  TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: (_) => setState(() => _showResults = true),
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
                                setState(() => _showResults = true);
                              },
                            )
                          : null,
                    ),
                  ),

                  // Results dropdown overlay
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
                        return DoctorResultsList(
                          doctors: filtered,
                          selectedId: _selectedDoctorId,
                          onSelect: _selectDoctor,
                        );
                      },
                    ),
                ],

                if (widget.showBranchFilter) ...[
                  const SizedBox(height: AppSizes.p16),

                  // ── Branch section ──
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
                        onTap: () =>
                            setState(() => _clinic = ClinicLocation.masrElgedida),
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

        // ── Pinned actions row at the bottom ──
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p20,
            AppSizes.p8,
            AppSizes.p20,
            AppSizes.p16,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAll,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Reset',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: PrimaryButton(
                  label: AppStrings.applyFilters,
                  onPressed: () => widget.onApplied(_selectedDoctorId, _clinic),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
