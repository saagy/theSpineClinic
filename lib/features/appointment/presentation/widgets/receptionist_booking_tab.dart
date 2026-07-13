import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_actions.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_controls.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_lists.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

class ReceptionistBookingTab extends ConsumerWidget {
  const ReceptionistBookingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingWorkboardProvider);
    final doctorsAsync = ref.watch(allDoctorsForFilterProvider);
    final user = ref.watch(currentUserProvider).value;
    final String? adminBranch = ref.watch(adminBranchFilterProvider);
    final ClinicLocation activeBranch = ref.watch(activeBranchProvider);
    final ClinicLocation? clinic = user?.role == UserRole.superAdmin
        ? ClinicLocation.values
              .where((b) => b.dbValue == adminBranch)
              .firstOrNull
        : activeBranch;

    if (clinic == null) {
      return const EmptyState(
        message: AppStrings.chooseBranchToStart,
        icon: Icons.location_on_outlined,
      );
    }
    final List<Staff> doctors = doctorsAsync.value ?? const [];
    final Staff? selected = doctors
        .where((doctor) => doctor.id == state.doctorId)
        .firstOrNull;
    if (state.doctorId != null && doctorsAsync.hasValue && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) =>
            ref.read(bookingWorkboardProvider.notifier).setDoctorFilter(null),
      );
    }
    final List<Staff> replacementDoctors =
        doctors.where((doctor) => doctor.isActive).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p12,
        AppSizes.p16,
        0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool wide =
                  constraints.maxWidth >=
                  AppSizes.appointmentWorkspaceBreakpoint;
              return Column(
                children: [
                  BookingWorkboardControls(
                    date: state.date,
                    doctor: selected,
                    onPreviousDay: () =>
                        BookingWorkboardActions.moveDay(ref, state.date, -1),
                    onNextDay: () =>
                        BookingWorkboardActions.moveDay(ref, state.date, 1),
                    onChooseDate: () => BookingWorkboardActions.chooseDate(
                      context,
                      ref,
                      state.date,
                    ),
                    onFilterDoctor: () =>
                        BookingWorkboardActions.showDoctorFilter(
                          context,
                          ref,
                          state,
                        ),
                    onReplaceDoctor:
                        selected != null &&
                            state.schedule.any(
                              (item) =>
                                  item.appointment.status !=
                                  AppointmentStatus.cancelled,
                            )
                        ? () => BookingWorkboardActions.replaceDoctor(
                            context,
                            ref,
                            selected,
                            replacementDoctors,
                            state,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSizes.p16),
                  Expanded(
                    child: BookingWorkboardLists(
                      state: state,
                      wide: wide,
                      onRefresh: ref
                          .read(bookingWorkboardProvider.notifier)
                          .refresh,
                      onViewChanged: ref
                          .read(bookingWorkboardProvider.notifier)
                          .selectView,
                      onCall: (patient) =>
                          BookingWorkboardActions.call(context, patient),
                      onBook: (patient) => BookingWorkboardActions.book(
                        context,
                        ref,
                        patient,
                        state,
                      ),
                      onRemind: (patient) =>
                          BookingWorkboardActions.remind(context, ref, patient),
                      onStop: (patient) =>
                          BookingWorkboardActions.stop(context, ref, patient),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
