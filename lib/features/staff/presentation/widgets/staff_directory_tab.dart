import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_active_filter_chips.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_filter_sheet.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_grouped_list.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
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
  final Set<int> _animatedIndices = <int>{};

  void _updateFilter(VoidCallback fn) => setState(() {
    fn();
    _animatedIndices.clear();
  });

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4),
            child: AppSearchBar(
              hintText: AppStrings.staffSearchHint,
              onChanged: (q) => _updateFilter(() => _query = q),
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
              onRole: (r) => _updateFilter(() => _filters = _filters.copyWith(role: () => r)),
              onStatus: (s) => _updateFilter(() => _filters = _filters.copyWith(status: () => s)),
              onBranch: (b) => _updateFilter(() => _filters = _filters.copyWith(branch: () => b)),
            ),
            onClearAll: () => _updateFilter(() => _filters = const StaffListFilters()),
          ),
          Expanded(child: _content(staffAsync)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () => context.push(AppRoutes.staffForm),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _content(AsyncValue<List<Staff>> staffAsync) {
    final Widget body = staffAsync.when(
      data: (staff) {
        final display = _filtered(staff);
        if (display.isEmpty) return KeyedSubtree(key: const ValueKey('staff_empty'), child: _empty());
        return KeyedSubtree(
          key: const ValueKey('staff_data'),
          child: StaffGroupedList(
            staffList: display,
            animatedIndices: _animatedIndices,
            onTap: (s) => context.push(AppRoutes.staffForm, extra: s),
          ),
        );
      },
      loading: () => const KeyedSubtree(key: ValueKey('staff_loading'), child: SkeletonTileList(count: 6)),
      error: (error, _) => KeyedSubtree(
        key: const ValueKey('staff_error'),
        child: ErrorView(
          exception: error is AppException ? error : AppException.fromSupabaseException(error),
          onRetry: () => ref.read(staffListProvider.notifier).refreshStaff(),
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        _animatedIndices.clear();
        await ref.read(staffListProvider.notifier).refreshStaff();
      },
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        child: body,
      ),
    );
  }

  List<Staff> _filtered(List<Staff> staff) {
    final q = _query.trim().toLowerCase();
    final list = staff.where((s) {
      final queryMatch = q.isEmpty || s.fullName.toLowerCase().contains(q) || s.email.toLowerCase().contains(q);
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
      options: StaffSortOption.values.map((o) => SortOption(value: o, label: o.displayLabel)).toList(),
    );
    if (selected != null && mounted) _updateFilter(() => _sort = selected);
  }

  Future<void> _showFilterSheet() async {
    final selected = await StaffFilterSheet.show(context: context, initialFilters: _filters);
    if (selected != null && mounted) _updateFilter(() => _filters = selected);
  }

  Widget _empty() => const SingleChildScrollView(
    physics: AlwaysScrollableScrollPhysics(),
    child: Center(
      child: Padding(
        padding: EdgeInsets.only(top: AppSizes.emptyStateTopOffset),
        child: EmptyState(message: AppStrings.noStaff, icon: Icons.people_alt_rounded),
      ),
    ),
  );
}
