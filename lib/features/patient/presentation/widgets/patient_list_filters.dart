/// Filter bar widget for the patient list screen with searchable doctor filter.
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

/// Renders doctor and branch filter controls for the patient list.
class PatientListFilters extends ConsumerWidget {
  const PatientListFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(activeDoctorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: Row(
        children: [
          Expanded(
            child: doctorsAsync.when(
              loading: () => const SizedBox(
                height: AppSizes.inputHeight,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (List<Staff> doctors) => _SearchableDoctorFilter(doctors: doctors),
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          Expanded(child: _BranchFilterChips()),
        ],
      ),
    );
  }
}

/// Searchable doctor filter using an overlay pattern similar to
/// [AppDoctorMultiSelectField] but for single-select.
class _SearchableDoctorFilter extends ConsumerStatefulWidget {
  const _SearchableDoctorFilter({required this.doctors});
  final List<Staff> doctors;

  @override
  ConsumerState<_SearchableDoctorFilter> createState() => _SearchableDoctorFilterState();
}

class _SearchableDoctorFilterState extends ConsumerState<_SearchableDoctorFilter> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchCtrl = TextEditingController();
  OverlayEntry? _overlayEntry;
  String _selectedDoctorName = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _searchCtrl.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (ctx) {
        final query = _searchCtrl.text.toLowerCase();
        final filtered = query.isEmpty
            ? widget.doctors
            : widget.doctors.where((d) => d.fullName.toLowerCase().contains(query)).toList();

        return Positioned(
          width: _layerLink.leaderSize?.width ?? AppSizes.navDrawerWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, AppSizes.overlayDropdownOffset),
            child: Material(
              elevation: AppSizes.overlayElevation,
              borderRadius: BorderRadius.circular(AppSizes.r6),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: const BoxConstraints(maxHeight: AppSizes.navDrawerWidth),
                color: AppColors.surface,
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    _FilterItem(
                      label: AppStrings.allDoctors,
                      onTap: () {
                        setState(() { _selectedDoctorName = ''; });
                        _searchCtrl.clear();
                        ref.read(patientListProvider.notifier).setDoctorFilter(null);
                        _hideOverlay();
                        _focusNode.unfocus();
                      },
                    ),
                    ...filtered.map((d) => _FilterItem(
                      label: d.fullName,
                      onTap: () {
                        setState(() { _selectedDoctorName = d.fullName; });
                        _searchCtrl.clear();
                        ref.read(patientListProvider.notifier).setDoctorFilter(d.id);
                        _hideOverlay();
                        _focusNode.unfocus();
                      },
                    )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPlaceholder = _selectedDoctorName.isEmpty;
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        height: AppSizes.inputHeight,
        child: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: (_) => _overlayEntry?.markNeedsBuild(),
          style: AppTextStyles.captionMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
            hintText: showPlaceholder ? AppStrings.filterByDoctor : _selectedDoctorName,
            hintStyle: AppTextStyles.captionMedium.copyWith(
              color: showPlaceholder ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            suffixIcon: _selectedDoctorName.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      setState(() { _selectedDoctorName = ''; });
                      ref.read(patientListProvider.notifier).setDoctorFilter(null);
                    },
                    child: const Icon(Icons.close, size: AppSizes.iconDefault, color: AppColors.textSecondary),
                  )
                : const Icon(Icons.search_rounded, size: AppSizes.iconDefault, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.borderStrong, width: AppSizes.borderWidthFocused),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  const _FilterItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p12),
        child: Text(label, style: AppTextStyles.captionMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _BranchFilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(patientListProvider.notifier);
    return Row(
      children: [
        Expanded(child: _BranchChip(label: AppStrings.allBranches, onTap: () => notifier.setClinicFilter(null))),
        const SizedBox(width: AppSizes.p4),
        Expanded(child: _BranchChip(label: ClinicLocation.tagamoa.displayLabel, onTap: () => notifier.setClinicFilter(ClinicLocation.tagamoa))),
        const SizedBox(width: AppSizes.p4),
        Expanded(child: _BranchChip(label: ClinicLocation.masrElgedida.displayLabel, onTap: () => notifier.setClinicFilter(ClinicLocation.masrElgedida))),
      ],
    );
  }
}

class _BranchChip extends StatelessWidget {
  const _BranchChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.inputHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
          border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
        ),
        child: Text(label, style: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
