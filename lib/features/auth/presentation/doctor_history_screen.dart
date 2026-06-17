import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/history_sort_option.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'widgets/history_filter_content.dart';
import 'widgets/doctor_history_list_view.dart';

/// Full-screen history view for a doctor's appointments.
class DoctorHistoryScreen extends ConsumerStatefulWidget {
  const DoctorHistoryScreen({super.key});

  @override
  ConsumerState<DoctorHistoryScreen> createState() => _DoctorHistoryScreenState();
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
      success: (items) => setState(() {
        _allItems = items;
        _isLoading = false;
        _applyFilters();
      }),
      failure: (_) => setState(() { _isLoading = false; _hasError = true; }),
    );
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    final end = _dateTo?.add(const Duration(days: 1));
    final result = _allItems.where((i) {
      if (q.isNotEmpty && !i.patient.fullName.toLowerCase().contains(q)) return false;
      if (_dateFrom != null && i.appointment.scheduledAt.isBefore(_dateFrom!)) return false;
      if (end != null && !i.appointment.scheduledAt.isBefore(end)) return false;
      if (_typeFilter != null && i.appointment.type != _typeFilter) return false;
      if (_branchFilter != null && i.patient.clinic != _branchFilter) return false;
      return true;
    }).toList();
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
          .map((o) => SortOption(value: o, label: o.displayLabel, buttonLabel: o.buttonLabel))
          .toList(),
      selected: _sortOption,
    );
    if (selected != null && mounted) setState(() => _sortOption = selected);
  }

  List<DoctorScheduleItem> _sorted(List<DoctorScheduleItem> items) {
    return List<DoctorScheduleItem>.from(items)..sort((a, b) {
      return switch (_sortOption) {
        HistorySortOption.dateNewest => b.appointment.scheduledAt.compareTo(a.appointment.scheduledAt),
        HistorySortOption.dateOldest => a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt),
        HistorySortOption.patientNameAsc => a.patient.fullName.toLowerCase().compareTo(b.patient.fullName.toLowerCase()),
        HistorySortOption.patientNameDesc => b.patient.fullName.toLowerCase().compareTo(a.patient.fullName.toLowerCase()),
      };
    });
  }

  List<ActiveFilterChip> get _activeChips {
    return [
      if (_dateFrom != null || _dateTo != null)
        ActiveFilterChip(
          label: _dateFrom != null && _dateTo != null
              ? '${_dateFrom!.month}/${_dateFrom!.day} – ${_dateTo!.month}/${_dateTo!.day}'
              : _dateFrom != null ? 'From ${_dateFrom!.month}/${_dateFrom!.day}' : 'To ${_dateTo!.month}/${_dateTo!.day}',
          onRemove: () => setState(() { _dateFrom = null; _dateTo = null; _applyFilters(); }),
        ),
      if (_typeFilter != null)
        ActiveFilterChip(label: _typeFilter!.displayLabel, onRemove: () => setState(() { _typeFilter = null; _applyFilters(); })),
      if (_branchFilter != null)
        ActiveFilterChip(label: _branchFilter!.displayLabel, onRemove: () => setState(() { _branchFilter = null; _applyFilters(); })),
    ];
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
              onChanged: (q) => setState(() { _searchQuery = q; _applyFilters(); }),
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
            onClearAll: () => setState(() {
              _dateFrom = null;
              _dateTo = null;
              _typeFilter = null;
              _branchFilter = null;
              _applyFilters();
            }),
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
                            TextButton(onPressed: _loadData, child: const Text(AppStrings.retry)),
                          ],
                        ),
                      )
                    : _filteredItems.isEmpty
                        ? const EmptyState(message: AppStrings.noHistoricAppointments, icon: Icons.history_rounded)
                        : DoctorHistoryListView(
                            items: _sorted(_filteredItems).take(_visibleCount).toList(),
                            scrollController: _scrollCtrl,
                            onRefresh: _loadData,
                          ),
          ),
        ],
      ),
    );
  }
}
