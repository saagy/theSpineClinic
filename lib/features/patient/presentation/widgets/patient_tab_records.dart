import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_notes_list_state.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_notes_sort_option.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/patient_notes_filter_content.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_note_item.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/slim_sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

class PatientTabRecords extends ConsumerStatefulWidget {
  const PatientTabRecords({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<PatientTabRecords> createState() =>
      _PatientTabRecordsState();
}

class _PatientTabRecordsState extends ConsumerState<PatientTabRecords> {
  final Set<int> _animatedIndices = <int>{};
  bool _notifiedLoadMore = false;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      if (!_notifiedLoadMore) {
        _notifiedLoadMore = true;
        ref
            .read(patientNotesListProvider(widget.patient.id).notifier)
            .loadMore()
            .then((_) => _notifiedLoadMore = false);
      }
    }
    return false;
  }

  Future<void> _showSortSheet() async {
    final state = ref.read(patientNotesListProvider(widget.patient.id));
    final notifier =
        ref.read(patientNotesListProvider(widget.patient.id).notifier);

    final selected =
        await SortOptionsSheet.show<PatientNotesSortOption>(
      context: context,
      title: AppStrings.sortOptions,
      options: PatientNotesSortOption.values
          .map((o) => SortOption(
              value: o, label: o.displayLabel, buttonLabel: o.buttonLabel))
          .toList(),
      selected: state.sort,
    );
    if (selected != null && mounted) notifier.setSort(selected);
  }

  void _openFilterSheet() {
    AppBottomSheet.show(
      context: context,
      title: AppStrings.filters,
      builder: (context, scrollController) =>
          PatientNotesFilterContent(
        patientId: widget.patient.id,
        scrollController: scrollController,
      ),
    );
  }

  List<ActiveFilterChip> _getActiveChips(
      PatientNotesListState state, PatientNotesList notifier) {
    final chips = <ActiveFilterChip>[];
    if (state.dateFrom != null || state.dateTo != null) {
      final label = state.dateFrom != null && state.dateTo != null
          ? '${Formatters.formatDateShort(state.dateFrom!)} – ${Formatters.formatDateShort(state.dateTo!.subtract(const Duration(days: 1)))}'
          : state.dateFrom != null
              ? 'From ${Formatters.formatDateShort(state.dateFrom!)}'
              : 'To ${Formatters.formatDateShort(state.dateTo!.subtract(const Duration(days: 1)))}';
      chips.add(ActiveFilterChip(
          label: label,
          onRemove: () => notifier.setDateRange(null, null)));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(patientNotesListProvider(widget.patient.id));
    if (state.isLoading) {
      _animatedIndices.clear();
    }
    final notifier =
        ref.read(patientNotesListProvider(widget.patient.id).notifier);
    final chips = _getActiveChips(state, notifier);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p4),
            child: AppButton(
              labelText: AppStrings.addNote,
              onPressed: () => _showAddNoteSheet(context),
              icon: Icons.add,
              shape: AppButtonShape.pill,
            ),
          ),
          SlimSortFilterBar(
            sortLabel: state.sort.buttonLabel,
            onSortTap: _showSortSheet,
            activeFilterCount: chips.length,
            onFilterTap: _openFilterSheet,
            totalCount: state.notes.isNotEmpty ? state.totalCount : null,
          ),
          if (chips.isNotEmpty)
            ActiveFilterChipsRow(
                chips: chips, onClearAll: notifier.clearFilters),
          Expanded(
            child: state.isLoading
                ? const SkeletonTileList(count: 4)
                : state.errorMessage != null
                    ? RefreshIndicator(
                        onRefresh: notifier.refresh,
                        color: cs.primary,
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: ErrorView(
                                exception: UnknownException(
                                    message: state.errorMessage!),
                                onRetry: notifier.refresh,
                              ),
                            ),
                          ),
                        ),
                      )
                    : state.notes.isEmpty
                        ? const EmptyState(
                            message: AppStrings.noNotesRecorded,
                            icon: Icons.history_edu_rounded)
                        : RefreshIndicator(
                            onRefresh: notifier.refresh,
                            color: cs.primary,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                  bottom: AppSizes.p16),
                              itemCount: state.notes.length +
                                  (state.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.notes.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: AppSizes.p16),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: AppSizes
                                                .strokeWidthThin)),
                                  );
                                }
                                final note = state.notes[index];
                                return AnimatedListItem(
                                  index: index,
                                  animatedIndices: _animatedIndices,
                                  child: PatientNoteItem(note: note),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
      ),
      builder: (_) => AddNoteSheet(patientId: widget.patient.id),
    );
  }
}
