import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointment_sort_option.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointments_state.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/slim_sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'patient_appointment_chips_helper.dart';
import 'patient_appointment_filter_content.dart';

class PatientTabAppointments extends ConsumerStatefulWidget {
  const PatientTabAppointments({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<PatientTabAppointments> createState() =>
      _PatientTabAppointmentsState();
}

class _PatientTabAppointmentsState
    extends ConsumerState<PatientTabAppointments> {
  final Set<int> _animatedIndices = <int>{};
  bool _notifiedLoadMore = false;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      if (!_notifiedLoadMore) {
        _notifiedLoadMore = true;
        ref
            .read(
                patientAppointmentsProvider(widget.patient.id).notifier)
            .loadMore()
            .then((_) => _notifiedLoadMore = false);
      }
    }
    return false;
  }

  Future<void> _showSortSheet() async {
    final state = ref.read(patientAppointmentsProvider(widget.patient.id));
    final notifier =
        ref.read(patientAppointmentsProvider(widget.patient.id).notifier);

    final selected =
        await SortOptionsSheet.show<PatientAppointmentSortOption>(
      context: context,
      title: AppStrings.sortOptions,
      options: PatientAppointmentSortOption.values
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
          PatientAppointmentFilterContent(
        patientId: widget.patient.id,
        scrollController: scrollController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;
    final state = ref.watch(patientAppointmentsProvider(widget.patient.id));
    if (state.isLoading) {
      _animatedIndices.clear();
    }
    final notifier =
        ref.read(patientAppointmentsProvider(widget.patient.id).notifier);
    final chips = buildPatientAppointmentChips(ref, state, notifier);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDoctor) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p4),
              child: AppButton(
                labelText: AppStrings.bookAppointment,
                onPressed: () => context.push(
                    '${AppRoutes.newAppointment}?patientId=${widget.patient.id}'),
              ),
            ),
          ],
          SlimSortFilterBar(
            sortLabel: state.sort.buttonLabel,
            onSortTap: _showSortSheet,
            activeFilterCount: chips.length,
            onFilterTap: _openFilterSheet,
            totalCount: state.appointments.isNotEmpty ? state.totalCount : null,
          ),
          if (chips.isNotEmpty)
            ActiveFilterChipsRow(
                chips: chips, onClearAll: notifier.clearFilters),
          Expanded(
            child: state.isLoading
                ? const SkeletonTileList(count: 4)
                : state.errorMessage != null
                    ? _buildErrorState(state, notifier)
                    : state.appointments.isEmpty
                        ? const EmptyState(
                            message: AppStrings.noAppointments,
                            icon: Icons.calendar_today_rounded)
                        : RefreshIndicator(
                            onRefresh: notifier.refresh,
                            color: cs.primary,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                  bottom: AppSizes.p16),
                              itemCount: state.appointments.length +
                                  (state.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.appointments.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: AppSizes.p16),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: AppSizes
                                                .strokeWidthThin)),
                                  );
                                }
                                final appointment =
                                    state.appointments[index];
                                final item = AppointmentWithPatient(
                                    appointment: appointment,
                                    patient: widget.patient);
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
      ),
    );
  }

  Widget _buildErrorState(
      PatientAppointmentsState state, PatientAppointments notifier) {
    final cs = Theme.of(context).colorScheme;
    final AppException ex =
        UnknownException(message: state.errorMessage ?? '');
    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () async => notifier.refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: ErrorView(exception: ex, onRetry: notifier.refresh),
          ),
        ),
      ),
    );
  }
}
