/// Full-screen shell for the doctor's historic appointments.
///
/// State (items, filters, sort, pagination) is owned by
/// [DoctorHistoryNotifier]. This widget is a thin renderer — only the
/// [ScrollController] is local UI state.
///
/// Rule 1 — under 200 lines.
/// Rule 9 — loading / error / empty / data states explicitly handled.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/auth/domain/history_sort_option.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_history_provider.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

import 'widgets/doctor_history_list_view.dart';
import 'widgets/history_filter_content.dart';

/// Full-screen history view for a doctor's appointments.
class DoctorHistoryScreen extends ConsumerStatefulWidget {
  const DoctorHistoryScreen({super.key});

  @override
  ConsumerState<DoctorHistoryScreen> createState() =>
      _DoctorHistoryScreenState();
}

class _DoctorHistoryScreenState
    extends ConsumerState<DoctorHistoryScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(doctorHistoryProvider.notifier).loadMore();
    }
  }

  Future<void> _showSortSheet(HistorySortOption current) async {
    final HistorySortOption? selected = await SortOptionsSheet.show<HistorySortOption>(
      context: context,
      title: 'Sort Options',
      options: HistorySortOption.values
          .map((o) => SortOption<HistorySortOption>(
                value: o,
                label: o.displayLabel,
                buttonLabel: o.buttonLabel,
              ))
          .toList(),
      selected: current,
    );
    if (selected != null && mounted) {
      ref.read(doctorHistoryProvider.notifier).setSortOption(selected);
    }
  }

  void _showFilterSheet(DoctorHistoryState current) {
    final notifier = ref.read(doctorHistoryProvider.notifier);
    AppBottomSheet.show<void>(
      context: context,
      title: 'Filters',
      builder: (ctx, scrollCtrl) => HistoryFilterContent(
        initialDateFrom: current.dateFrom,
        initialDateTo: current.dateTo,
        initialType: current.typeFilter,
        initialBranch: current.branchFilter,
        scrollController: scrollCtrl,
        onApplied: ({
          required DateTime? dateFrom,
          required DateTime? dateTo,
          required AppointmentType? type,
          required ClinicLocation? clinic,
        }) {
          // Fan out into per-field setters. Each routes through copyWith
          // with explicit `null` for cleared values (sentinel pattern
          // inside copyWith distinguishes null from "leave unchanged").
          notifier.setDateRange(dateFrom, dateTo);
          notifier.setTypeFilter(type);
          notifier.setBranchFilter(clinic);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  List<ActiveFilterChip> _buildChips(DoctorHistoryState state) {
    final notifier = ref.read(doctorHistoryProvider.notifier);
    return <ActiveFilterChip>[
      // Each chip's onRemove targets only its own field, matching the
      // ActiveFilterChip contract ("remove this filter") and the
      // behaviour of every other filter surface in the app.
      if (state.dateRangeLabel != null)
        ActiveFilterChip(
          label: state.dateRangeLabel!,
          onRemove: notifier.clearDateRange,
        ),
      if (state.typeFilter != null)
        ActiveFilterChip(
          label: state.typeFilter!.displayLabel,
          onRemove: notifier.clearTypeFilter,
        ),
      if (state.branchFilter != null)
        ActiveFilterChip(
          label: state.branchFilter!.displayLabel,
          onRemove: notifier.clearBranchFilter,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final DoctorHistoryState state =
        ref.watch(doctorHistoryProvider);
    final notifier = ref.read(doctorHistoryProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(AppStrings.historicAppointments,
            style: AppTextStyles.headingSmall),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4),
            child: AppSearchBar(
              hintText: AppStrings.searchByPatientNameHint,
              onChanged: notifier.setSearchQuery,
            ),
          ),
          SortFilterBar(
            sortLabel: 'Sort: ${state.sortOption.buttonLabel}',
            onSortTap: () => _showSortSheet(state.sortOption),
            activeFilterCount: state.hasFilters ? 1 : 0,
            onFilterTap: () => _showFilterSheet(state),
          ),
          if (state.hasFilters)
            ActiveFilterChipsRow(
              chips: _buildChips(state),
              onClearAll: notifier.clearFilters,
            ),
          Expanded(child: _buildBody(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(DoctorHistoryState state, DoctorHistoryNotifier notifier) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.p16),
        child: SkeletonTileList(count: 6),
      );
    }
    final error = state.error;
    if (error != null) {
      final AppException ex = error is AppException
          ? error
          : AppException.fromSupabaseException(error);
      return ErrorView(exception: ex, onRetry: notifier.refresh);
    }
    final items = state.visibleItems;
    if (items.isEmpty) {
      return const EmptyState(
        message: AppStrings.noHistoricAppointments,
        icon: Icons.history_rounded,
      );
    }
    return DoctorHistoryListView(
      items: items,
      scrollController: _scrollCtrl,
      onRefresh: notifier.refresh,
      onStatusChanged: notifier.refresh,
    );
  }
}
