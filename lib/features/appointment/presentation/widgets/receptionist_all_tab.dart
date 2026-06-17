/// The "All" tab content: search bar, sort/filter controls, active filter chips,
/// and a date-grouped appointment list with infinite-scroll pagination.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_content.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/all_filter_chips_helper.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

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
    final n = ref.read(allAppointmentsProvider.notifier);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4),
        child: AppSearchBar(hintText: AppStrings.searchByPatientNameHint, onChanged: n.searchPatient),
      ),
      SortFilterBar(sortLabel: 'Sort: $_sortLabel', onSortTap: _showSortSheet,
        activeFilterCount: _chips.length, onFilterTap: () => _openFilterSheet(context)),
      ActiveFilterChipsRow(chips: _chips, onClearAll: () => ref.read(allAppointmentsProvider.notifier).clearAll()),
      Expanded(child: _body(async)),
    ]);
  }

  Widget _body(AsyncValue<List<AppointmentWithPatient>> async) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
        child: SkeletonTileList(count: 6),
      ),
      error: (e, _) => ErrorView(exception: UnknownException(message: '$e'),
        onRetry: () => ref.read(allAppointmentsProvider.notifier).clearAll()),
      data: (items) {
        if (items.isEmpty) return const EmptyState(message: AppStrings.noAppointmentsFound, icon: Icons.event_busy_rounded);
        final bool loadingMore = ref.watch(isLoadingMoreProvider);
        final list = _buildList(items);
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
                                color: AppColors.primary))));
              }
              final item = list[i];
              if (item is _HeaderItem) {
                return Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
                    child: Text(item.title,
                        style: AppTextStyles.captionBold
                            .copyWith(color: AppColors.textSecondary)));
              }
              final a = (item as _ApptItem).item;
              return ReceptionistAppointmentCard(
                      item: a,
                      showMenu: true,
                      onStatusChanged: widget.onStatusChanged)
                  .animate()
                  .fadeIn(duration: 250.ms, delay: (i * 30).ms);
            },
          ),
        );
      },
    );
  }

  List<_ListItem> _buildList(List<AppointmentWithPatient> items) {
    final result = <_ListItem>[];
    String? last;
    for (final item in items) {
      final d = item.appointment.scheduledAt.toLocal();
      final h = _header(d);
      if (h != last) { result.add(_HeaderItem(h)); last = h; }
      result.add(_ApptItem(item));
    }
    return result;
  }

  String _header(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final comp = DateTime(d.year, d.month, d.day);
    final diff = today.difference(comp).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return DateFormat('EEEE, MMM d').format(d);
  }

  void _openFilterSheet(BuildContext context) {
    AppBottomSheet.show(context: context, title: 'Advanced Filters',
      builder: (ctx, scrollCtrl) => AppointmentFilterContent(scrollController: scrollCtrl));
  }
}

sealed class _ListItem {}
class _HeaderItem extends _ListItem { _HeaderItem(this.title); final String title; }
class _ApptItem extends _ListItem { _ApptItem(this.item); final AppointmentWithPatient item; }
