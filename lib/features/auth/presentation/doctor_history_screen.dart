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

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_history_provider.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

import 'widgets/doctor_history_list_view.dart';
import 'widgets/history_filter_content.dart';
import 'package:spine_clinic_app/shared/widgets/search_filter_toolbar.dart';

/// Full-screen history view for a doctor's appointments.
class DoctorHistoryScreen extends ConsumerStatefulWidget {
  const DoctorHistoryScreen({super.key});

  @override
  ConsumerState<DoctorHistoryScreen> createState() => _DoctorHistoryScreenState();
}

class _DoctorHistoryScreenState extends ConsumerState<DoctorHistoryScreen> {
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
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(doctorHistoryProvider.notifier).loadMore();
    }
  }

  List<ActiveFilterChip> _buildChips(DoctorHistoryState state) {
    final notifier = ref.read(doctorHistoryProvider.notifier);
    return <ActiveFilterChip>[
      // Each chip's onRemove targets only its own field, matching the
      // ActiveFilterChip contract ("remove this filter") and the
      // behaviour of every other filter surface in the app.
      if (state.dateRangeLabel != null)
        ActiveFilterChip(label: state.dateRangeLabel!, onRemove: notifier.clearDateRange),
      if (state.typeFilter != null)
        ActiveFilterChip(label: state.typeFilter!.displayLabel, onRemove: notifier.clearTypeFilter),
      if (state.branchFilter != null)
        ActiveFilterChip(
          label: state.branchFilter!.displayLabel,
          onRemove: notifier.clearBranchFilter,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final DoctorHistoryState state = ref.watch(doctorHistoryProvider);
    final notifier = ref.read(doctorHistoryProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(AppStrings.historicAppointments, style: AppTextStyles.headingSmall),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16,
              AppSizes.p12,
              AppSizes.p16,
              AppSizes.p4,
            ),
            child: SearchFilterToolbar(
              query: state.searchQuery,
              onSearch: notifier.setSearchQuery,
              activeCount: _buildChips(state).length,
              onFilter: () => showHistoryFilters(context, ref),
            ),
          ),
          if (state.hasFilters)
            ActiveFilterChipsRow(chips: _buildChips(state), onClearAll: notifier.clearFilters),
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
