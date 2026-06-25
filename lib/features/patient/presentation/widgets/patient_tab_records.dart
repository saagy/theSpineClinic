import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_notes_sort_option.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/patient_notes_filter_content.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_note_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';

/// Renders a chronological feed of patient notes with pagination, sorting, and filtering.
class PatientTabRecords extends ConsumerStatefulWidget {
  const PatientTabRecords({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<PatientTabRecords> createState() => _PatientTabRecordsState();
}

class _PatientTabRecordsState extends ConsumerState<PatientTabRecords> {
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
      ref.read(patientNotesListProvider(widget.patient.id).notifier).loadMore();
    }
  }

  Future<void> _showSortSheet() async {
    final state = ref.read(patientNotesListProvider(widget.patient.id));
    final notifier = ref.read(patientNotesListProvider(widget.patient.id).notifier);

    final selected = await SortOptionsSheet.show<PatientNotesSortOption>(
      context: context,
      title: 'Sort Options',
      options: PatientNotesSortOption.values
          .map((o) => SortOption(value: o, label: o.displayLabel, buttonLabel: o.buttonLabel))
          .toList(),
      selected: state.sort,
    );
    if (selected != null && mounted) notifier.setSort(selected);
  }

  void _openFilterSheet() {
    AppBottomSheet.show(
      context: context,
      title: 'Filters',
      builder: (context, scrollController) => PatientNotesFilterContent(
        patientId: widget.patient.id,
        scrollController: scrollController,
      ),
    );
  }

  List<ActiveFilterChip> _getActiveChips(dynamic state, dynamic notifier) {
    final chips = <ActiveFilterChip>[];
    if (state.dateFrom != null || state.dateTo != null) {
      final label = state.dateFrom != null && state.dateTo != null
          ? '${Formatters.formatDateShort(state.dateFrom!)} – ${Formatters.formatDateShort(state.dateTo!.subtract(const Duration(days: 1)))}'
          : state.dateFrom != null
              ? 'From ${Formatters.formatDateShort(state.dateFrom!)}'
              : 'To ${Formatters.formatDateShort(state.dateTo!.subtract(const Duration(days: 1)))}';
      chips.add(ActiveFilterChip(label: label, onRemove: () => notifier.setDateRange(null, null)));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientNotesListProvider(widget.patient.id));
    if (state.isLoading) {
      _animatedIndices.clear();
    }
    final notifier = ref.read(patientNotesListProvider(widget.patient.id).notifier);
    final chips = _getActiveChips(state, notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p16, AppSizes.p16, AppSizes.p8),
          child: AppButton(
            labelText: 'Add Note',
            onPressed: () => _showAddNoteSheet(context),
            icon: Icons.add,
            shape: AppButtonShape.pill,
          ),
        ),
        SortFilterBar(
          sortLabel: 'Sort: ${state.sort.buttonLabel}',
          onSortTap: _showSortSheet,
          activeFilterCount: chips.length,
          onFilterTap: _openFilterSheet,
        ),
        ActiveFilterChipsRow(chips: chips, onClearAll: notifier.clearFilters),
        if (state.notes.isNotEmpty && !state.isLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p8, AppSizes.p20, AppSizes.p4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total Notes: ${state.totalCount}',
                style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        Expanded(
          child: state.isLoading
              ? const SkeletonTileList(count: 4)
              : state.errorMessage != null
                  ? ErrorView(
                      exception: UnknownException(message: state.errorMessage!),
                      onRetry: notifier.refresh,
                    )
                  : state.notes.isEmpty
                      ? const EmptyState(message: 'No notes recorded yet', icon: Icons.history_edu_rounded)
                      : RefreshIndicator(
                          onRefresh: notifier.refresh,
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.only(bottom: AppSizes.p16),
                            itemCount: state.notes.length + (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.notes.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidthThin)),
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
    );
  }

  void _showAddNoteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddNoteSheet(patientId: widget.patient.id),
    );
  }
}
