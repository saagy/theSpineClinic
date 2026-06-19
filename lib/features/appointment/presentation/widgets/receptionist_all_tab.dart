/// The "All" tab content: search bar, sort/filter controls, active filter chips,
/// and a date-grouped appointment list with infinite-scroll pagination.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_content.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/all_filter_chips_helper.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_helpers.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_async_state_handler.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';

/// The "All" tab for the receptionist dashboard. Mirrors the standalone
/// [AllAppointmentsScreen] but embeds as a tab and uses [ReceptionistAppointmentCard]
/// for visual consistency with the Today / Upcoming tabs.
class ReceptionistAllTab extends ConsumerStatefulWidget {
  /// Creates a [ReceptionistAllTab].
  const ReceptionistAllTab({super.key, required this.onStatusChanged});
  final VoidCallback onStatusChanged;

  @override
  ConsumerState<ReceptionistAllTab> createState() => _ReceptionistAllTabState();
}

class _ReceptionistAllTabState extends ConsumerState<ReceptionistAllTab> {
  final ScrollController _scrollCtrl = ScrollController();
  final Set<int> _animatedIndices = <int>{};

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
      ref.read(allAppointmentsProvider.notifier).loadMore();
    }
  }

  // ── Sort ────────────────────────────────────────────────────────────────────

  String get _sortLabel {
    return ref.read(allAppointmentsProvider.notifier).isAscending ? 'Date ↑' : 'Date ↓';
  }

  Future<void> _showSortSheet() async {
    final n = ref.read(allAppointmentsProvider.notifier);
    final currentAsc = n.isAscending;
    final selected = await SortOptionsSheet.show<String>(
      context: context,
      title: 'Sort by Date',
      options: const [
        SortOption(value: 'newest', label: 'Date (Newest)', buttonLabel: 'Date ↓'),
        SortOption(value: 'oldest', label: 'Date (Oldest)', buttonLabel: 'Date ↑'),
      ],
      selected: currentAsc ? 'oldest' : 'newest',
    );
    if (selected != null && mounted) n.setSortAscending(selected == 'oldest');
  }

  List<ActiveFilterChip> get _chips => buildAllFilterChips(ref);

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allAppointmentsProvider);
    if (async.isLoading && async.value == null) {
      _animatedIndices.clear();
    }
    final n = ref.read(allAppointmentsProvider.notifier);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4),
        child: AppSearchBar(hintText: AppStrings.searchByPatientNameHint, onChanged: n.searchPatient),
      ),
      SortFilterBar(sortLabel: 'Sort: $_sortLabel', onSortTap: _showSortSheet,
        activeFilterCount: _chips.length, onFilterTap: () => _openFilterSheet(context)),
      ActiveFilterChipsRow(chips: _chips, onClearAll: () => ref.read(allAppointmentsProvider.notifier).clearAll()),
      if (async.value != null && !async.isLoading)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p8, AppSizes.p20, AppSizes.p4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Total Appointments: ${ref.read(allAppointmentsProvider.notifier).totalCount}',
              style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      Expanded(
        child: AppAsyncStateHandler<List<AppointmentWithPatient>>(
          asyncValue: async,
          onRetry: () => ref.read(allAppointmentsProvider.notifier).refresh(),
          emptyMessage: AppStrings.noAppointmentsFound,
          emptyIcon: Icons.event_busy_rounded,
          skeletonCount: 6,
          onData: (items) => _buildDataView(items),
        ),
      ),
    ]);
  }

  Widget _buildDataView(List<AppointmentWithPatient> items) {
    if (items.isEmpty) {
      return const EmptyState(
        message: AppStrings.noAppointmentsFound,
        icon: Icons.event_busy_rounded,
      );
    }
    final bool loadingMore = ref.watch(isLoadingMoreProvider);
    final list = buildDateGroupedList(items);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          ref.read(allAppointmentsProvider.notifier).refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollCtrl,
        padding: const EdgeInsets.only(bottom: AppSizes.p32),
        itemCount: list.length + (loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == list.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
              child: Center(
                child: SizedBox(
                  width: AppSizes.iconDefault,
                  height: AppSizes.iconDefault,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.strokeWidthThin,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }
          final item = list[i];
          if (item is AllHeaderItem) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8,
              ),
              child: Text(
                item.title,
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          final a = (item as AllApptItem).item;
          return AnimatedListItem(
            index: i,
            animatedIndices: _animatedIndices,
            child: ReceptionistAppointmentCard(
              item: a,
              showMenu: true,
              onStatusChanged: widget.onStatusChanged,
            ),
          );
        },
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    AppBottomSheet.show(context: context, title: 'Advanced Filters',
      builder: (ctx, scrollCtrl) => AppointmentFilterContent(scrollController: scrollCtrl));
  }
}
