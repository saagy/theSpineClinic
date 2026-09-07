import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_appointment_chips_helper.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_appointment_tab_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_appointments_error_state.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/slim_sort_filter_bar.dart';

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
            .read(patientAppointmentsProvider(widget.patient.id).notifier)
            .loadMore()
            .then((_) => _notifiedLoadMore = false);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final isRegularDoctor =
        user?.role == UserRole.doctor && !(user?.isSeniorDoctor ?? false);
    final state = ref.watch(patientAppointmentsProvider(widget.patient.id));
    if (state.isLoading) {
      _animatedIndices.clear();
    }
    final notifier = ref.read(
      patientAppointmentsProvider(widget.patient.id).notifier,
    );
    final chips = buildPatientAppointmentChips(ref, state, notifier);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isRegularDoctor)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p4,
              ),
              child: AppButton(
                labelText: AppStrings.bookAppointment,
                onPressed: () => PatientAppointmentTabActions.openNewAppointment(
                  context: context,
                  ref: ref,
                  patientId: widget.patient.id,
                ),
                shape: AppButtonShape.pill,
              ),
            ),
          SlimSortFilterBar(
            sortLabel: state.sort.buttonLabel,
            onSortTap: () => PatientAppointmentTabActions.showSortSheet(
              context: context,
              ref: ref,
              patientId: widget.patient.id,
            ),
            activeFilterCount: chips.length,
            onFilterTap: () => PatientAppointmentTabActions.openFilterSheet(
              context,
              widget.patient.id,
            ),
            totalCount: state.appointments.isNotEmpty ? state.totalCount : null,
          ),
          if (chips.isNotEmpty)
            ActiveFilterChipsRow(
              chips: chips,
              onClearAll: notifier.clearFilters,
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: state.isLoading
                  ? const KeyedSubtree(
                      key: ValueKey('patient_appts_loading'),
                      child: SkeletonTileList(count: 4),
                    )
                  : state.errorMessage != null
                  ? KeyedSubtree(
                      key: const ValueKey('patient_appts_error'),
                      child: PatientAppointmentsErrorState(
                        message: state.errorMessage,
                        onRefresh: notifier.refresh,
                      ),
                    )
                  : state.appointments.isEmpty
                  ? const KeyedSubtree(
                      key: ValueKey('patient_appts_empty'),
                      child: EmptyState(
                        message: AppStrings.noAppointments,
                        icon: Icons.calendar_today_rounded,
                      ),
                    )
                  : KeyedSubtree(
                      key: ValueKey(
                        'patient_appts_data_${state.appointments.length}',
                      ),
                      child: RefreshIndicator(
                        onRefresh: notifier.refresh,
                        color: cs.primary,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: AppSizes.p16),
                          itemCount: state.appointments.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.appointments.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSizes.p16,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: AppSizes.strokeWidthThin,
                                  ),
                                ),
                              );
                            }
                            final item = state.appointments[index];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedListItem(
                                  index: index,
                                  animatedIndices: _animatedIndices,
                                  child: AppointmentAgendaRow(
                                    item: item,
                                    showDoctor: true,
                                    onStatusChanged: notifier.refresh,
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: AppSizes.borderWidth,
                                  color: cs.outlineVariant.withAlpha(80),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}