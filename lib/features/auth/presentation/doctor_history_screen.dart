/// Paginated history screen for a doctor's past and present appointments.
///
/// Features debounced search by patient name, date-range filter,
/// appointment-type filter, and infinite‑scroll pagination.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Full-screen history view for a doctor's appointments.
class DoctorHistoryScreen extends ConsumerStatefulWidget {
  /// Creates a [DoctorHistoryScreen].
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
  int _visibleCount = 30;

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

    setState(() {
      _filteredItems = result;
      _visibleCount = 30.clamp(0, result.length);
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_dateFrom ?? DateTime.now().subtract(const Duration(days: 30))) : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
      _applyFilters();
    }
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
          _buildFilterBar(),
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
                        : ListView.builder(
                            controller: _scrollCtrl,
                            itemCount: _filteredItems.length.clamp(0, _visibleCount),
                            itemBuilder: (_, index) {
                              final item = _filteredItems[index];
                              return DataListTile(
                                title: item.patient.fullName,
                                subtitle: '${item.appointment.type.displayLabel} · ${Formatters.formatDateMedium(item.appointment.scheduledAt)}',
                                onTap: () => context.push(
                                  AppRoutes.appointmentDetail.replaceAll(':id', item.appointment.id),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
      child: Wrap(
        spacing: AppSizes.p8,
        runSpacing: AppSizes.p8,
        children: [
          // Date from
          ActionChip(
            avatar: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(_dateFrom != null ? Formatters.formatDateShort(_dateFrom!) : AppStrings.fromDate),
            onPressed: () => _pickDate(true),
            backgroundColor: _dateFrom != null ? AppColors.primaryLight : AppColors.surface,
          ),
          // Date to
          ActionChip(
            avatar: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(_dateTo != null ? Formatters.formatDateShort(_dateTo!) : AppStrings.toDate),
            onPressed: () => _pickDate(false),
            backgroundColor: _dateTo != null ? AppColors.primaryLight : AppColors.surface,
          ),
          // Type filter
          ...AppointmentType.values.map((type) {
            final isSelected = _typeFilter == type;
            return ActionChip(
              label: Text(type.displayLabel, style: AppTextStyles.caption.copyWith(color: isSelected ? AppColors.primary : AppColors.textSecondary)),
              backgroundColor: isSelected ? AppColors.primaryLight : AppColors.surface,
              onPressed: () {
                setState(() => _typeFilter = isSelected ? null : type);
                _applyFilters();
              },
            );
          }),
          // Clear filters
          if (_dateFrom != null || _dateTo != null || _typeFilter != null)
            ActionChip(
              avatar: const Icon(Icons.clear_rounded, size: 16, color: AppColors.error),
              label: Text(AppStrings.clearFilters, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              onPressed: () {
                setState(() {
                  _dateFrom = null;
                  _dateTo = null;
                  _typeFilter = null;
                });
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }
}
