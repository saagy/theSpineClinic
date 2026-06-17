import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointment_sort_option.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'patient_appointment_filter_content.dart';

/// Renders a chronological list of appointments for a patient with pagination and sorting/filtering.
class PatientTabAppointments extends ConsumerStatefulWidget {
  const PatientTabAppointments({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<PatientTabAppointments> createState() => _PatientTabAppointmentsState();
}

class _PatientTabAppointmentsState extends ConsumerState<PatientTabAppointments> {
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
      ref.read(patientAppointmentsProvider(widget.patient.id).notifier).loadMore();
    }
  }

  Future<void> _showSortSheet() async {
    final state = ref.read(patientAppointmentsProvider(widget.patient.id));
    final notifier = ref.read(patientAppointmentsProvider(widget.patient.id).notifier);

    final selected = await SortOptionsSheet.show<PatientAppointmentSortOption>(
      context: context,
      title: 'Sort Options',
      options: PatientAppointmentSortOption.values
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
      builder: (context, scrollController) => PatientAppointmentFilterContent(
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
    if (state.statusFilter != null && state.statusFilter!.isNotEmpty) {
      chips.add(ActiveFilterChip(label: 'Status (${state.statusFilter!.length})', onRemove: () => notifier.setStatusFilter(null)));
    }
    if (state.typeFilter != null && state.typeFilter!.isNotEmpty) {
      chips.add(ActiveFilterChip(label: 'Type (${state.typeFilter!.length})', onRemove: () => notifier.setTypeFilter(null)));
    }
    if (state.doctorId != null) {
      final doctors = ref.watch(activeDoctorsProvider).value ?? [];
      final doctor = doctors.cast<Staff?>().firstWhere((d) => d!.id == state.doctorId, orElse: () => null);
      chips.add(ActiveFilterChip(label: doctor?.fullName ?? 'Doctor', onRemove: () => notifier.setDoctorFilter(null)));
    }
    if (state.usePackageFilter != null) {
      chips.add(ActiveFilterChip(
        label: state.usePackageFilter!
            ? AppStrings.packageFilterPackage
            : AppStrings.packageFilterNoPackage,
        onRemove: () => notifier.setUsePackageFilter(null),
      ));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;
    final state = ref.watch(patientAppointmentsProvider(widget.patient.id));
    if (state.isLoading) {
      _animatedIndices.clear();
    }
    final notifier = ref.read(patientAppointmentsProvider(widget.patient.id).notifier);
    final chips = _getActiveChips(state, notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDoctor) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p16, AppSizes.p16, AppSizes.p8),
            child: AppButton(
              labelText: AppStrings.bookAppointment,
              onPressed: () => context.push('${AppRoutes.newAppointment}?patientId=${widget.patient.id}'),
            ),
          ),
        ],
        SortFilterBar(
          sortLabel: 'Sort: ${state.sort.buttonLabel}',
          onSortTap: _showSortSheet,
          activeFilterCount: chips.length,
          onFilterTap: _openFilterSheet,
        ),
        ActiveFilterChipsRow(chips: chips, onClearAll: notifier.clearFilters),
        if (state.appointments.isNotEmpty && !state.isLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p8, AppSizes.p20, AppSizes.p4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total Appointments: ${state.totalCount}',
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
                  : state.appointments.isEmpty
                      ? const EmptyState(message: AppStrings.noAppointments, icon: Icons.calendar_today_rounded)
                      : RefreshIndicator(
                          onRefresh: notifier.refresh,
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.only(bottom: AppSizes.p16),
                            itemCount: state.appointments.length + (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.appointments.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidthThin)),
                                );
                              }
                              final appointment = state.appointments[index];
                              final item = AppointmentWithPatient(appointment: appointment, patient: widget.patient);
                              return AnimatedListItem(
                                index: index,
                                animatedIndices: _animatedIndices,
                                child: ReceptionistAppointmentCard(
                                  item: item,
                                  showMenu: true,
                                  showDate: true,
                                  onStatusChanged: notifier.refresh,
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
