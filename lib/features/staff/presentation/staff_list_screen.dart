import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';

/// Screen listing all non-doctor staff members.
/// Enforces Super Admin role-based protection on mount.
class StaffListScreen extends ConsumerWidget {
  /// Creates a [StaffListScreen].
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.superAdmin) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorView(
              exception: UnknownException(
                message: AppStrings.errorDatabasePermissionDenied,
                code: 'security/blocked',
              ),
            ),
          );
        }

        return const _StaffListScaffold();
      },
    );
  }
}

enum StaffSortOption {
  nameAsc,
  nameDesc,
  roleAsc;

  String get displayLabel => switch (this) {
    StaffSortOption.nameAsc => 'Name (A → Z)',
    StaffSortOption.nameDesc => 'Name (Z → A)',
    StaffSortOption.roleAsc => 'Role (A → Z)',
  };

  String get buttonLabel => switch (this) {
    StaffSortOption.nameAsc => 'Name A→Z',
    StaffSortOption.nameDesc => 'Name Z→A',
    StaffSortOption.roleAsc => 'Role',
  };
}

class _StaffListScaffold extends ConsumerStatefulWidget {
  const _StaffListScaffold();

  @override
  ConsumerState<_StaffListScaffold> createState() => _StaffListScaffoldState();
}

class _StaffListScaffoldState extends ConsumerState<_StaffListScaffold> {
  StaffSortOption _sortOption = StaffSortOption.nameAsc;
  String _searchQuery = '';
  bool? _activeStatusFilter; // null = all, true = active, false = inactive

  Future<void> _showSortSheet() async {
    final selected = await SortOptionsSheet.show<StaffSortOption>(
      context: context,
      title: 'Sort Options',
      options: StaffSortOption.values
          .map((o) => SortOption(
                value: o,
                label: o.displayLabel,
                buttonLabel: o.buttonLabel,
              ))
          .toList(),
      selected: _sortOption,
    );
    if (selected != null && mounted) {
      setState(() => _sortOption = selected);
    }
  }

  List<Staff> _sorted(List<Staff> staff) {
    final list = List<Staff>.from(staff);
    switch (_sortOption) {
      case StaffSortOption.nameAsc:
        list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      case StaffSortOption.nameDesc:
        list.sort((a, b) => b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase()));
      case StaffSortOption.roleAsc:
        list.sort((a, b) => a.role.dbValue.compareTo(b.role.dbValue));
    }
    return list;
  }

  void _showFilterSheet() {
    final currentRoleFilter = ref.read(staffFilterProvider);
    String localRole = currentRoleFilter;
    bool? localStatus = _activeStatusFilter;

    AppBottomSheet.show(
      context: context,
      title: 'Filters',
      builder: (ctx, scrollCtrl) => StatefulBuilder(
        builder: (context, setSheetState) {
          return UnifiedFilterSheet(
            initialDoctorId: null,
            initialClinic: null,
            showDoctorFilter: false,
            showBranchFilter: false,
            scrollController: scrollCtrl,
            additionalFilters: [
              const SectionHeader(title: 'Role'),
              const SizedBox(height: AppSizes.p8),
              Wrap(
                spacing: AppSizes.p8,
                runSpacing: AppSizes.p8,
                children: [
                  AppFilterChip(
                    label: AppStrings.all,
                    isActive: localRole == 'All',
                    onTap: () { localRole = 'All'; setSheetState(() {}); },
                  ),
                  AppFilterChip(
                    label: AppStrings.superAdmin,
                    isActive: localRole == 'super_admin',
                    onTap: () { localRole = 'super_admin'; setSheetState(() {}); },
                  ),
                  AppFilterChip(
                    label: AppStrings.receptionist,
                    isActive: localRole == 'receptionist',
                    onTap: () { localRole = 'receptionist'; setSheetState(() {}); },
                  ),
                  AppFilterChip(
                    label: AppStrings.doctor,
                    isActive: localRole == 'doctor',
                    onTap: () { localRole = 'doctor'; setSheetState(() {}); },
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p16),
              const SectionHeader(title: 'Status'),
              const SizedBox(height: AppSizes.p8),
              Wrap(
                spacing: AppSizes.p8,
                runSpacing: AppSizes.p8,
                children: [
                  AppFilterChip(
                    label: 'All',
                    isActive: localStatus == null,
                    onTap: () { localStatus = null; setSheetState(() {}); },
                  ),
                  AppFilterChip(
                    label: 'Active',
                    isActive: localStatus == true,
                    onTap: () { localStatus = true; setSheetState(() {}); },
                  ),
                  AppFilterChip(
                    label: 'Inactive',
                    isActive: localStatus == false,
                    onTap: () { localStatus = false; setSheetState(() {}); },
                  ),
                ],
              ),
            ],
            onReset: () {
              ref.read(staffFilterProvider.notifier).setFilter('All');
              setState(() => _activeStatusFilter = null);
              Navigator.of(ctx).pop();
            },
            onApplied: (String? doctorId, ClinicLocation? clinic) {
              ref.read(staffFilterProvider.notifier).setFilter(localRole);
              setState(() => _activeStatusFilter = localStatus);
              Navigator.of(ctx).pop();
            },
          );
        },
      ),
    );
  }

  List<ActiveFilterChip> get _activeChips {
    final chips = <ActiveFilterChip>[];
    final roleFilter = ref.watch(staffFilterProvider);
    if (roleFilter != 'All') {
      chips.add(ActiveFilterChip(
        label: roleFilter == 'super_admin'
            ? AppStrings.superAdmin
            : roleFilter == 'receptionist'
                ? AppStrings.receptionist
                : AppStrings.doctor,
        onRemove: () => ref.read(staffFilterProvider.notifier).setFilter('All'),
      ));
    }
    if (_activeStatusFilter != null) {
      chips.add(ActiveFilterChip(
        label: _activeStatusFilter! ? 'Active' : 'Inactive',
        onRemove: () => setState(() => _activeStatusFilter = null),
      ));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final filteredStaffAsync = ref.watch(filteredStaffProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(AppStrings.staffManagement),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4,
            ),
            child: AppSearchBar(
              hintText: AppStrings.searchPatients,
              onChanged: (query) => setState(() => _searchQuery = query),
            ),
          ),
          SortFilterBar(
            sortLabel: 'Sort: ${_sortOption.buttonLabel}',
            onSortTap: _showSortSheet,
            activeFilterCount: _activeChips.length,
            onFilterTap: _showFilterSheet,
          ),
          ActiveFilterChipsRow(
            chips: _activeChips,
            onClearAll: () {
              ref.read(staffFilterProvider.notifier).setFilter('All');
              setState(() => _activeStatusFilter = null);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(staffListProvider.notifier).refreshStaff(),
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: filteredStaffAsync.when(
                data: (staffList) {
                  List<Staff> display = _sorted(staffList);
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    display = display.where((s) =>
                      s.fullName.toLowerCase().contains(q) ||
                      s.email.toLowerCase().contains(q)
                    ).toList();
                  }
                  if (_activeStatusFilter != null) {
                    display = display
                        .where((s) => s.isActive == _activeStatusFilter)
                        .toList();
                  }
                  if (display.isEmpty) {
                    return const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: AppSizes.emptyStateTopOffset),
                          child: EmptyState(
                            message: AppStrings.noStaff,
                            icon: Icons.people_alt_rounded,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: display.length,
                    itemBuilder: (context, index) {
                      final staff = display[index];
                      return _StaffRow(staff: staff);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => ErrorView(
                  exception: error is AppException ? error : AppException.fromSupabaseException(error),
                  onRetry: () => ref.read(staffListProvider.notifier).refreshStaff(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.staffForm),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.staff});

  final Staff staff;

  @override
  Widget build(BuildContext context) {
    final String roleLabel;
    final Color roleTextColor;
    final Color roleBgColor;

    switch (staff.role) {
      case UserRole.superAdmin:
        roleLabel = AppStrings.superAdmin;
        roleTextColor = AppColors.primary;
        roleBgColor = AppColors.primaryLight;
        break;
      case UserRole.receptionist:
        roleLabel = AppStrings.receptionist;
        roleTextColor = AppColors.success;
        roleBgColor = AppColors.successBg;
        break;
      case UserRole.doctor:
        roleLabel = AppStrings.doctor;
        roleTextColor = AppColors.info;
        roleBgColor = AppColors.infoBg;
        break;
    }

    return DataListTile(
      title: staff.fullName,
      subtitle: staff.email,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBadge(
            label: roleLabel,
            textColor: roleTextColor,
            backgroundColor: roleBgColor,
          ),
          const SizedBox(width: AppSizes.p8),
          AppBadge(
            label: staff.isActive ? 'Active' : 'Inactive',
            textColor: staff.isActive ? AppColors.success : AppColors.error,
            backgroundColor: staff.isActive ? AppColors.successBg : AppColors.errorBg,
          ),
        ],
      ),
      onTap: () => context.push(AppRoutes.staffForm, extra: staff),
    );
  }
}
