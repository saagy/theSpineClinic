/// Paginated history screen for a doctor's past and present appointments.
///
/// Features debounced search by patient name, date-range filter,
/// appointment-type filter, and infinite‑scroll pagination.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'widgets/history_filter_content.dart';

/// Full-screen history view for a doctor's appointments.
class DoctorHistoryScreen extends ConsumerStatefulWidget {
  /// Creates a [DoctorHistoryScreen].
  const DoctorHistoryScreen({super.key});

  @override
  ConsumerState<DoctorHistoryScreen> createState() => _DoctorHistoryScreenState();
}

enum HistorySortOption {
  dateNewest,
  dateOldest,
  patientNameAsc,
  patientNameDesc;

  String get displayLabel => switch (this) {
    HistorySortOption.dateNewest => 'Date (Newest)',
    HistorySortOption.dateOldest => 'Date (Oldest)',
    HistorySortOption.patientNameAsc => 'Patient Name (A → Z)',
    HistorySortOption.patientNameDesc => 'Patient Name (Z → A)',
  };

  String get buttonLabel => switch (this) {
    HistorySortOption.dateNewest => 'Date ↓',
    HistorySortOption.dateOldest => 'Date ↑',
    HistorySortOption.patientNameAsc => 'Name A→Z',
    HistorySortOption.patientNameDesc => 'Name Z→A',
  };
}

class _DoctorHistoryScreenState extends ConsumerState<DoctorHistoryScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  List<DoctorScheduleItem> _allItems = [];
  List<DoctorScheduleItem> _filteredItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  AppointmentType? _typeFilter;
  ClinicLocation? _branchFilter;
  int _visibleCount = 30;
  HistorySortOption _sortOption = HistorySortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      setState(() => _visibleCount = (_visibleCount + 30).clamp(0, _filteredItems.length));
    }
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() { _isLoading = true; _hasError = false; });

    final repo = ref.read(appointmentRepositoryProvider);
    final result = await repo.getDoctorSchedule(user.id);

    if (!mounted) return;

    result.when(
      success: (items) {
        setState(() {
          _allItems = items;
          _isLoading = false;
          _applyFilters();
        });
      },
      failure: (_) {
        setState(() { _isLoading = false; _hasError = true; });
      },
    );
  }

  void _applyFilters() {
    List<DoctorScheduleItem> result = List<DoctorScheduleItem>.from(_allItems);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) => i.patient.fullName.toLowerCase().contains(q)).toList();
    }
    if (_dateFrom != null) {
      final DateTime from = _dateFrom!;
      result = result.where((i) => !i.appointment.scheduledAt.isBefore(from)).toList();
    }
    if (_dateTo != null) {
      final DateTime end = _dateTo!.add(const Duration(days: 1));
      result = result.where((i) => i.appointment.scheduledAt.isBefore(end)).toList();
    }
    if (_typeFilter != null) {
      final AppointmentType type = _typeFilter!;
      result = result.where((i) => i.appointment.type == type).toList();
    }
    if (_branchFilter != null) {
      final ClinicLocation branch = _branchFilter!;
      result = result.where((i) => i.patient.clinic == branch).toList();
    }

    setState(() {
      _filteredItems = result;
      _visibleCount = 30.clamp(0, result.length);
    });
  }

  Future<void> _showSortSheet() async {
    final selected = await SortOptionsSheet.show<HistorySortOption>(
      context: context,
      title: 'Sort Options',
      options: HistorySortOption.values
          .map((o) => SortOption(
                value: o,
                label: o.displayLabel,
                buttonLabel: o.buttonLabel,
              ))
          .toList(),
      selected: _sortOption,
    );
    if (selected != null && mounted) {
      setState(() => _sortOption = selected);
    }
  }

  List<DoctorScheduleItem> _sorted(List<DoctorScheduleItem> items) {
    final list = List<DoctorScheduleItem>.from(items);
    switch (_sortOption) {
      case HistorySortOption.dateNewest:
        list.sort((a, b) => b.appointment.scheduledAt.compareTo(a.appointment.scheduledAt));
      case HistorySortOption.dateOldest:
        list.sort((a, b) => a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt));
      case HistorySortOption.patientNameAsc:
        list.sort((a, b) => a.patient.fullName.toLowerCase().compareTo(b.patient.fullName.toLowerCase()));
      case HistorySortOption.patientNameDesc:
        list.sort((a, b) => b.patient.fullName.toLowerCase().compareTo(a.patient.fullName.toLowerCase()));
    }
    return list;
  }

  List<ActiveFilterChip> get _activeChips {
    final chips = <ActiveFilterChip>[];
    // Date range — single combined chip (matching All Appointments pattern)
    final bool hasDateFrom = _dateFrom != null;
    final bool hasDateTo = _dateTo != null;
    if (hasDateFrom || hasDateTo) {
      String label;
      if (hasDateFrom && hasDateTo) {
        label = '${Formatters.formatDateShort(_dateFrom!)} – ${Formatters.formatDateShort(_dateTo!)}';
      } else if (hasDateFrom) {
        label = 'From ${Formatters.formatDateShort(_dateFrom!)}';
      } else {
        label = 'To ${Formatters.formatDateShort(_dateTo!)}';
      }
      chips.add(ActiveFilterChip(
        label: label,
        onRemove: () {
          setState(() { _dateFrom = null; _dateTo = null; });
          _applyFilters();
        },
      ));
    }
    if (_typeFilter != null) {
      chips.add(ActiveFilterChip(
        label: _typeFilter!.displayLabel,
        onRemove: () { setState(() => _typeFilter = null); _applyFilters(); },
      ));
    }
    if (_branchFilter != null) {
      chips.add(ActiveFilterChip(
        label: _branchFilter!.displayLabel,
        onRemove: () { setState(() => _branchFilter = null); _applyFilters(); },
      ));
    }
    return chips;
  }

  void _showFilterSheet() {
    AppBottomSheet.show(
      context: context,
      title: 'Filters',
      builder: (ctx, scrollCtrl) => HistoryFilterContent(
        initialDateFrom: _dateFrom,
        initialDateTo: _dateTo,
        initialType: _typeFilter,
        initialBranch: _branchFilter,
        scrollController: scrollCtrl,
        onApplied: ({required dateFrom, required dateTo, required type, required clinic}) {
          setState(() {
            _dateFrom = dateFrom;
            _dateTo = dateTo;
            _typeFilter = type;
            _branchFilter = clinic;
          });
          _applyFilters();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  List<_ListItem> _buildListItems(List<DoctorScheduleItem> items) {
    final List<_ListItem> listItems = [];
    String? lastHeader;

    for (final item in items) {
      final date = item.appointment.scheduledAt.toLocal();
      final header = _getGroupHeader(date);
      if (header != lastHeader) {
        listItems.add(_HeaderItem(header));
        lastHeader = header;
      }
      listItems.add(_HistoryItem(item));
    }
    return listItems;
  }

  String _getGroupHeader(DateTime date) {
    final DateTime localDate = date.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime comparisonDate = DateTime(localDate.year, localDate.month, localDate.day);

    final int difference = today.difference(comparisonDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';
    return DateFormat('EEEE, MMM d').format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(AppStrings.historicAppointments, style: AppTextStyles.headingSmall),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4),
            child: AppSearchBar(
              hintText: AppStrings.searchByPatientNameHint,
              onChanged: _onSearchChanged,
            ),
          ),
          SortFilterBar(
            sortLabel: 'Sort: ${_sortOption.buttonLabel}',
            onSortTap: _showSortSheet,
            activeFilterCount: _activeChips.length,
            onFilterTap: _showFilterSheet,
          ),
          ActiveFilterChipsRow(
            chips: _activeChips,
            onClearAll: () {
              setState(() {
                _dateFrom = null;
                _dateTo = null;
                _typeFilter = null;
                _branchFilter = null;
              });
              _applyFilters();
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppStrings.errorDatabaseGeneric, style: AppTextStyles.bodySecondary),
                            const SizedBox(height: AppSizes.p16),
                            TextButton(onPressed: _loadData, child: Text(AppStrings.retry)),
                          ],
                        ),
                      )
                    : _filteredItems.isEmpty
                        ? const EmptyState(message: AppStrings.noHistoricAppointments, icon: Icons.history_rounded)
                        : (() {
                            final sorted = _sorted(_filteredItems);
                            final cappedData = sorted.take(_visibleCount).toList();
                            final List<_ListItem> displayItems = _buildListItems(cappedData);
                            return ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.only(
                                left: AppSizes.p16,
                                right: AppSizes.p16,
                                bottom: AppSizes.p32,
                              ),
                              itemCount: displayItems.length,
                              itemBuilder: (_, int index) {
                                final _ListItem listItem = displayItems[index];
                                if (listItem is _HeaderItem) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSizes.p8, AppSizes.p20, AppSizes.p8, AppSizes.p8,
                                    ),
                                    child: Text(
                                      listItem.title,
                                      style: AppTextStyles.captionBold.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }
                                final DoctorScheduleItem item = (listItem as _HistoryItem).item;
                                return DataListTile(
                                  key: ValueKey(item.appointment.id),
                                  title: item.patient.fullName,
                                  subtitle: '${item.appointment.type.displayLabel} · '
                                      '${Formatters.formatTime(item.appointment.scheduledAt.toLocal())}',
                                  leading: AppAvatar(
                                    name: item.patient.fullName,
                                    radius: AppSizes.avatarTile / 2,
                                  ),
                                  trailing: AppointmentActionsTrailing(appointment: item.appointment),
                                  onTap: () => context.push(
                                    AppRoutes.appointmentDetail.replaceAll(':id', item.appointment.id),
                                  ),
                                ).animate().fadeIn(
                                      duration: 250.ms,
                                      delay: (index * 30).ms,
                                    );
                              },
                            );
                          })(),
          ),
        ],
      ),
    );
  }
}

sealed class _ListItem {}

class _HeaderItem extends _ListItem {
  _HeaderItem(this.title);
  final String title;
}

class _HistoryItem extends _ListItem {
  _HistoryItem(this.item);
  final DoctorScheduleItem item;
}
