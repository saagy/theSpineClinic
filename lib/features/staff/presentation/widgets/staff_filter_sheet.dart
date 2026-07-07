import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';
import 'package:spine_clinic_app/shared/widgets/responsive_button_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';

class StaffFilterSheet extends StatefulWidget {
  const StaffFilterSheet({
    super.key,
    required this.initialFilters,
    required this.scrollController,
  });

  final StaffListFilters initialFilters;
  final ScrollController scrollController;

  static Future<StaffListFilters?> show({
    required BuildContext context,
    required StaffListFilters initialFilters,
  }) {
    return AppBottomSheet.show<StaffListFilters>(
      context: context,
      title: AppStrings.filters,
      builder: (_, scrollController) => StaffFilterSheet(
        initialFilters: initialFilters,
        scrollController: scrollController,
      ),
    );
  }

  @override
  State<StaffFilterSheet> createState() => _StaffFilterSheetState();
}

class _StaffFilterSheetState extends State<StaffFilterSheet> {
  late StaffListFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _roleSection(),
                const SizedBox(height: AppSizes.p16),
                _statusSection(),
                const SizedBox(height: AppSizes.p16),
                _branchSection(),
              ],
            ),
          ),
        ),
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
                labelText: AppStrings.clearAll,
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    Navigator.of(context).pop(const StaffListFilters()),
              ),
              AppButton(
                labelText: AppStrings.applyFilters,
                onPressed: () => Navigator.of(context).pop(_filters),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleSection() {
    return _chips(
      title: AppStrings.filterByRole,
      children: [
        _chip(AppStrings.allRoles, _filters.role == null, () {
          _set(role: () => null);
        }),
        for (final role in UserRole.values)
          _chip(_roleLabel(role), _filters.role == role, () {
            _set(role: () => role);
          }),
      ],
    );
  }

  Widget _statusSection() {
    return _chips(
      title: AppStrings.filterByStatus,
      children: [
        _chip(AppStrings.allStatuses, _filters.status == null, () {
          _set(status: () => null);
        }),
        for (final status in StaffAccountStatus.values.where(
          (s) => s != StaffAccountStatus.pending,
        ))
          _chip(status.label, _filters.status == status, () {
            _set(status: () => status);
          }),
      ],
    );
  }

  Widget _branchSection() {
    return _chips(
      title: AppStrings.filterByBranch,
      children: [
        _chip(AppStrings.allBranches, _filters.branch == null, () {
          _set(branch: () => null);
        }),
        for (final branch in ClinicLocation.values)
          _chip(branch.displayLabel, _filters.branch == branch, () {
            _set(branch: () => branch);
          }),
      ],
    );
  }

  Widget _chips({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSizes.p8),
        Wrap(spacing: AppSizes.p8, runSpacing: AppSizes.p8, children: children),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return AppFilterChip(label: label, isActive: selected, onTap: onTap);
  }

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.superAdmin => AppStrings.superAdmin,
    UserRole.receptionist => AppStrings.receptionist,
    UserRole.doctor => AppStrings.doctor,
  };

  void _set({
    UserRole? Function()? role,
    StaffAccountStatus? Function()? status,
    ClinicLocation? Function()? branch,
  }) {
    setState(() {
      _filters = _filters.copyWith(role: role, status: status, branch: branch);
    });
  }
}
