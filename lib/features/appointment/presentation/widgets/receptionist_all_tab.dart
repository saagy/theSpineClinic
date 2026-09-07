/// The "All" tab content: search bar, sort/filter controls, active filter chips,
/// and a date-grouped appointment list with infinite-scroll pagination.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/all_filter_chips_helper.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_helpers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_list.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_async_state_handler.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';

/// The "All" tab for the receptionist dashboard. Mirrors the standalone
/// [AllAppointmentsScreen] but embeds as a tab and uses [AppointmentAgendaRow]
/// for unified operational density and visual consistency.
class ReceptionistAllTab extends ConsumerStatefulWidget {
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
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(allAppointmentsProvider.notifier).loadMore();
    }
  }

  String get _sortLabel {
    return ref.read(allAppointmentsProvider.notifier).isAscending
        ? 'Date \u2191'
        : 'Date \u2193';
  }

  List<ActiveFilterChip> get _chips => buildAllFilterChips(ref);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allAppointmentsProvider);
    if (async.isLoading && async.value == null) {
      _animatedIndices.clear();
    }
    final n = ref.read(allAppointmentsProvider.notifier);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16,
            AppSizes.p12,
            AppSizes.p16,
            AppSizes.p4,
          ),
          child: AppSearchBar(
            hintText: AppStrings.searchByPatientNameHint,
            onChanged: n.searchPatient,
          ),
        ),
        SortFilterBar(
          sortLabel: 'Sort: $_sortLabel',
          onSortTap: () => showAllSortSheet(context, ref),
          activeFilterCount: _chips.length,
          onFilterTap: () => openAllFilterSheet(context),
        ),
        ActiveFilterChipsRow(
          chips: _chips,
          onClearAll: () =>
              ref.read(allAppointmentsProvider.notifier).clearAll(),
        ),
        if (async.value != null && !async.isLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p20,
              AppSizes.p8,
              AppSizes.p20,
              AppSizes.p4,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total Appointments: ${ref.read(allAppointmentsProvider.notifier).totalCount}',
                style: AppTextStyles.captionBold.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
            onData: (items) => ReceptionistAllList(
              items: items,
              scrollController: _scrollCtrl,
              animatedIndices: _animatedIndices,
              onStatusChanged: widget.onStatusChanged,
            ),
          ),
        ),
      ],
    );
  }
}