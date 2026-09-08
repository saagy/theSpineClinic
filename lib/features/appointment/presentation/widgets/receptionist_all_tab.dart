/// The "All" tab content: search bar, filter button with badge indicator,
/// responsive table header and page navigation on desktop, and date-grouped
/// list with infinite scroll on mobile.
///
/// Rule 1 — under 200 lines.
/// Rule 7 — AppStrings constants.
/// Rule 8 — AppSizes tokens.
/// Rule 9 — loading, error, empty, and data states handled.
/// Rule 11 — desktop and mobile responsiveness.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_table_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_search_field.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_filter_button.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_helpers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_list.dart';
import 'package:spine_clinic_app/shared/widgets/app_async_state_handler.dart';
import 'package:spine_clinic_app/shared/widgets/app_table_pagination.dart';

/// The "All" tab for receptionist / admin appointments management.
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
    // Only use infinite scroll on mobile viewports.
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= AppSizes.desktopBreakpoint;
    if (isDesktop) return;

    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      final notifier = ref.read(allAppointmentsProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  void _onPrevious() {
    ref.read(allAppointmentsProvider.notifier).previousPage();
    _resetScroll();
  }

  void _onNext() {
    ref.read(allAppointmentsProvider.notifier).nextPage();
    _resetScroll();
  }

  void _resetScroll() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allAppointmentsProvider);
    if (async.isLoading && async.value == null) {
      _animatedIndices.clear();
    }
    final n = ref.read(allAppointmentsProvider.notifier);
    final activeFiltersCount = n.activeFiltersCount;
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= AppSizes.desktopBreakpoint;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16,
            AppSizes.p12,
            AppSizes.p16,
            AppSizes.p8,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppointmentSearchField(
                  onChanged: n.searchPatient,
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              ReceptionistAllFilterButton(
                activeFiltersCount: activeFiltersCount,
                onTap: () => openAllFilterSheet(context, ref),
              ),
            ],
          ),
        ),
        if (async.value != null && !async.isLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p20,
              AppSizes.p4,
              AppSizes.p20,
              AppSizes.p4,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${AppStrings.totalAppointments}: ${n.totalCount}',
                style: AppTextStyles.captionBold.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (isDesktop)
          const AppointmentAgendaTableHeader(showDoctor: true),
        Expanded(
          child: AppAsyncStateHandler<List<AppointmentWithPatient>>(
            asyncValue: async,
            onRetry: () => ref.read(allAppointmentsProvider.notifier).refresh(),
            emptyMessage: AppStrings.noAppointmentsFound,
            emptyIcon: Icons.event_busy_rounded,
            skeletonCount: 6,
            onData: (items) {
              final displayItems = isDesktop && items.length > n.pageSize
                  ? items.sublist(
                      ((n.currentPage - 1) * n.pageSize).clamp(0, items.length),
                      (n.currentPage * n.pageSize).clamp(0, items.length),
                    )
                  : items;
              return ReceptionistAllList(
                items: displayItems,
                scrollController: _scrollCtrl,
                animatedIndices: _animatedIndices,
                onStatusChanged: widget.onStatusChanged,
              );
            },
          ),
        ),
        if (isDesktop && async.hasValue && (async.value?.isNotEmpty ?? false))
          AppTablePagination(
            currentPage: n.currentPage,
            totalPages: n.totalPages,
            totalCount: n.totalCount,
            pageSize: n.pageSize,
            hasPrevious: n.hasPreviousPage,
            hasNext: n.hasNextPage,
            onPrevious: _onPrevious,
            onNext: _onNext,
            entityLabel: AppStrings.paginationAppointments,
          ),
      ],
    );
  }
}