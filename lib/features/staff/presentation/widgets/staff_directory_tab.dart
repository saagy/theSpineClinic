import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_active_filter_chips.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_filter_sheet.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_grouped_list.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

/// Tab view displaying the searchable, filterable staff roster for admin management.
class StaffDirectoryTab extends ConsumerStatefulWidget {
  /// Creates a [StaffDirectoryTab] instance.
  const StaffDirectoryTab({super.key});

  @override
  ConsumerState<StaffDirectoryTab> createState() => _StaffDirectoryTabState();
}

class _StaffDirectoryTabState extends ConsumerState<StaffDirectoryTab> {
  StaffSortOption _sort = StaffSortOption.nameAsc;
  StaffListFilters _filters = const StaffListFilters();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16,
              AppSizes.p12,
              AppSizes.p16,
              AppSizes.p4,
            ),
            child: AppSearchBar(
              hintText: AppStrings.staffSearchHint,
              onChanged: (query) => setState(() => _query = query),
            ),
          ),
          SortFilterBar(
            sortLabel: '${AppStrings.sort}: ${_sort.displayLabel}',
            onSortTap: _showSortSheet,
            activeFilterCount: _filters.activeCount,
            onFilterTap: _showFilterSheet,
          ),
          ActiveFilterChipsRow(
            chips: staffActiveFilterChips(
              filters: _filters,
              onRole: _setRole,
              onStatus: _setStatus,
              onBranch: _setBranch,
            ),
            onClearAll: () =>
                setState(() => _filters = const StaffListFilters()),
          ),
          Expanded(child: _content(staffAsync)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => context.push(AppRoutes.staffForm),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _content(AsyncValue<List<Staff>> staffAsync) {
    return RefreshIndicator(
      onRefresh: () => ref.read(staffListProvider.notifier).refreshStaff(),
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: staffAsync.when(
        data: (staff) {
          final display = _filtered(staff);
          if (display.isEmpty) return _empty();
          return StaffGroupedList(
            staffList: display,
            onTap: (s) => context.push(AppRoutes.staffForm, extra: s),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        error: (error, _) => ErrorView(
          exception: error is AppException
              ? error
              : AppException.fromSupabaseException(error),
          onRetry: () => ref.read(staffListProvider.notifier).refreshStaff(),
        ),
      ),
    );
  }

  List<Staff> _filtered(List<Staff> staff) {
    final q = _query.trim().toLowerCase();
    final list = staff.where((s) {
      final queryMatch =
          q.isEmpty ||
          s.fullName.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q);
      return queryMatch && _filters.matches(s);
    }).toList();
    switch (_sort) {
      case StaffSortOption.nameAsc:
        list.sort((a, b) => a.fullName.compareTo(b.fullName));
      case StaffSortOption.nameDesc:
        list.sort((a, b) => b.fullName.compareTo(a.fullName));
      case StaffSortOption.roleAsc:
        list.sort((a, b) => a.role.dbValue.compareTo(b.role.dbValue));
      case StaffSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  Future<void> _showSortSheet() async {
    final selected = await SortOptionsSheet.show<StaffSortOption>(
      context: context,
      title: AppStrings.sortOptions,
      selected: _sort,
      options: StaffSortOption.values
          .map(
            (option) => SortOption(value: option, label: option.displayLabel),
          )
          .toList(),
    );
    if (selected != null && mounted) setState(() => _sort = selected);
  }

  Future<void> _showFilterSheet() async {
    final selected = await StaffFilterSheet.show(
      context: context,
      initialFilters: _filters,
    );
    if (selected != null && mounted) setState(() => _filters = selected);
  }

  Widget _empty() => const SingleChildScrollView(
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

  void _setRole(UserRole? role) =>
      setState(() => _filters = _filters.copyWith(role: () => role));
  void _setStatus(StaffAccountStatus? status) =>
      setState(() => _filters = _filters.copyWith(status: () => status));
  void _setBranch(ClinicLocation? branch) =>
      setState(() => _filters = _filters.copyWith(branch: () => branch));
}
