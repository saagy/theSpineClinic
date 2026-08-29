import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_tile.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Unified bottom sheet for doctor selection in single or multi-select modes.
class DoctorPickerSheet extends ConsumerStatefulWidget {
  const DoctorPickerSheet({
    super.key,
    required this.selectedDoctorIds,
    required this.isMultiSelect,
    this.showAllOption = false,
    this.showDeactivated = true,
    this.excludeDoctorIds,
    this.scrollController,
  });

  final Set<String> selectedDoctorIds;
  final bool isMultiSelect;
  final bool showAllOption;
  final bool showDeactivated;
  final List<String>? excludeDoctorIds;
  final ScrollController? scrollController;

  static Future<List<Staff>?> showMulti({
    required BuildContext context,
    required List<Staff> initialSelected,
    bool showDeactivated = false,
    List<String>? excludeDoctorIds,
    String? title,
  }) {
    final selectedIds = initialSelected.map((d) => d.id).toSet();
    return AppBottomSheet.show<List<Staff>>(
      context: context,
      title: title ?? AppStrings.selectDoctors,
      builder: (_, scrollCtrl) => DoctorPickerSheet(
        selectedDoctorIds: selectedIds,
        isMultiSelect: true,
        showDeactivated: showDeactivated,
        excludeDoctorIds: excludeDoctorIds,
        scrollController: scrollCtrl,
      ),
    );
  }

  static Future<Staff?> showSingle({
    required BuildContext context,
    String? selectedDoctorId,
    bool showAllOption = false,
    bool showDeactivated = true,
    List<String>? excludeDoctorIds,
    String? title,
  }) {
    final selectedIds = selectedDoctorId != null ? {selectedDoctorId} : <String>{};
    return AppBottomSheet.show<Staff?>(
      context: context,
      title: title ?? AppStrings.chooseDoctor,
      builder: (_, scrollCtrl) => DoctorPickerSheet(
        selectedDoctorIds: selectedIds,
        isMultiSelect: false,
        showAllOption: showAllOption,
        showDeactivated: showDeactivated,
        excludeDoctorIds: excludeDoctorIds,
        scrollController: scrollCtrl,
      ),
    );
  }

  @override
  ConsumerState<DoctorPickerSheet> createState() => _DoctorPickerSheetState();
}

class _DoctorPickerSheetState extends ConsumerState<DoctorPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late Set<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.selectedDoctorIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onDoctorTap(Staff doctor, List<Staff> allDoctors) {
    if (!widget.isMultiSelect) {
      Navigator.of(context).pop(doctor);
      return;
    }
    setState(() {
      if (_selectedIds.contains(doctor.id)) {
        _selectedIds.remove(doctor.id);
      } else {
        _selectedIds.add(doctor.id);
      }
    });
  }

  void _onDone(List<Staff> allDoctors) {
    final selected = allDoctors.where((d) => _selectedIds.contains(d.id)).toList();
    Navigator.of(context).pop(selected);
  }

  List<Staff> _filter(List<Staff> doctors) {
    final q = _query.trim().toLowerCase();
    Iterable<Staff> list = doctors;
    if (widget.excludeDoctorIds != null) {
      list = list.where((d) => !widget.excludeDoctorIds!.contains(d.id));
    }
    if (!widget.showDeactivated) {
      list = list.where((d) => d.isActive);
    }
    final filtered = q.isEmpty
        ? list.toList()
        : list.where((d) => d.fullName.toLowerCase().contains(q)).toList();
    filtered.sort((a, b) {
      if (a.isActive == b.isActive) return a.fullName.compareTo(b.fullName);
      return a.isActive ? -1 : 1;
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doctorsAsync = widget.showDeactivated
        ? ref.watch(allDoctorsForFilterProvider)
        : ref.watch(activeDoctorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16,
            0,
            AppSizes.p16,
            AppSizes.p8,
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _query = val),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: AppStrings.searchDoctorsHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: doctorsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSizes.p16),
              child: SkeletonTileList(count: 4),
            ),
            error: (_, __) => Center(
              child: Text(
                AppStrings.errorLoadingDoctors,
                style: AppTextStyles.bodySecondary.copyWith(color: cs.error),
              ),
            ),
            data: (allDoctors) {
              final filtered = _filter(allDoctors);
              final itemCount = filtered.length + (widget.showAllOption ? 1 : 0);

              if (filtered.isEmpty && !widget.showAllOption) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.p24),
                    child: Text(
                      AppStrings.noMatchingDoctorsFound,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSizes.p16),
                itemCount: itemCount,
                itemBuilder: (ctx, index) {
                  if (widget.showAllOption && index == 0) {
                    final bool isAllSelected = _selectedIds.isEmpty;
                    return _AllDoctorsOptionTile(
                      isSelected: isAllSelected,
                      onTap: () => Navigator.of(context).pop(null),
                    );
                  }
                  final docIndex = widget.showAllOption ? index - 1 : index;
                  final doctor = filtered[docIndex];
                  return DoctorPickerTile(
                    doctor: doctor,
                    isSelected: _selectedIds.contains(doctor.id),
                    isMultiSelect: widget.isMultiSelect,
                    onTap: () => _onDoctorTap(doctor, allDoctors),
                  );
                },
              );
            },
          ),
        ),
        if (widget.isMultiSelect)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16,
              AppSizes.p8,
              AppSizes.p16,
              AppSizes.p16,
            ),
            child: AppButton(
              labelText: '${AppStrings.done} (${AppStrings.selectedCount(_selectedIds.length)})',
              onPressed: doctorsAsync.hasValue
                  ? () => _onDone(doctorsAsync.value!)
                  : null,
              shape: AppButtonShape.pill,
            ),
          ),
      ],
    );
  }
}

class _AllDoctorsOptionTile extends StatelessWidget {
  const _AllDoctorsOptionTile({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p4,
      ),
      child: Material(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          side: BorderSide(
            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.7),
            width: isSelected ? AppSizes.borderWidthFocused : AppSizes.borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.avatarMedium / 2,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.people_alt_rounded, color: cs.primary),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Text(
                    AppStrings.allDoctors,
                    style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
