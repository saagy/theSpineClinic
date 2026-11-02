import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/new_appointment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/pending_booking_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_actions.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import '../../fixtures/booking_return_repositories.dart';
import '../../fixtures/workspace_data.dart';

class _User extends CurrentUser {
  @override
  Future<Staff?> build() async => workspaceStaff('reception');
}

class _Branch extends ActiveBranch {
  @override
  ClinicLocation build() => ClinicLocation.tagamoa;
}

void main() {
  for (final outcome in ['save', 'cancel', 'back', 'failure']) {
    testWidgets('booking $outcome retains workboard context on return', (
      tester,
    ) async {
      final appointments = BookingReturnAppointments()
        ..failBooking = outcome == 'failure';
      final patients = BookingReturnPatients(appointments);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(_User.new),
          activeBranchProvider.overrideWith(_Branch.new),
          appointmentRepositoryProvider.overrideWithValue(appointments),
          patientRepositoryProvider.overrideWithValue(patients),
          patientDetailProvider(
            bookingReturnPatient.id,
          ).overrideWith((ref) async => bookingReturnPatient),
          pendingBookingProvider(
            bookingReturnPatient.id,
          ).overrideWith((ref) async => false),
          availableBalanceForTypeProvider((
            patientId: bookingReturnPatient.id,
            type: AppointmentType.normalPtSession,
          )).overrideWith((ref) async => 4),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final board = ref.watch(bookingWorkboardProvider);
                  return TextButton(
                    onPressed: () => BookingWorkboardActions.book(
                      context,
                      ref,
                      bookingReturnPatient,
                      board,
                    ),
                    child: const Text(AppStrings.book),
                  );
                },
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.newAppointment,
            builder: (context, state) => NewAppointmentScreen(
              preselectedPatientId: state.uri.queryParameters['patientId'],
              preselectedDate: DateTime.parse(
                state.uri.queryParameters['date']!,
              ),
              preselectedDoctorId: state.uri.queryParameters['doctorId'],
              expectedNextVisitDate: DateTime.parse(
                state.uri.queryParameters['dueDate']!,
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final selectedDate = DateUtils.dateOnly(
        DateTime.now().add(const Duration(days: 30)),
      );
      final board = container.read(bookingWorkboardProvider.notifier);
      await board.selectDate(selectedDate);
      await board.setDoctorFilter(workspaceStaff('doctor').id);
      board.selectView(BookingWorkboardView.schedule);
      await tester.pumpAndSettle();
      final initialQueryCount = appointments.scheduleQueries.length;

      await tester.tap(find.text(AppStrings.book));
      await tester.pumpAndSettle();
      expect(find.byType(NewAppointmentScreen), findsOneWidget);
      if (outcome == 'back') {
        await tester.tap(find.byTooltip(AppStrings.backTooltip));
      } else {
        await tester.tap(
          find.text(outcome == 'cancel' ? AppStrings.cancel : AppStrings.save),
        );
      }
      await tester.pumpAndSettle();
      if (outcome == 'failure') {
        expect(find.byType(NewAppointmentScreen), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.backTooltip));
        await tester.pumpAndSettle();
      }

      expect(find.byType(NewAppointmentScreen), findsNothing);
      expect(find.text(AppStrings.book), findsOneWidget);
      final result = container.read(bookingWorkboardProvider);
      expect(result.date, selectedDate);
      expect(result.doctorId, workspaceStaff('doctor').id);
      expect(result.view, BookingWorkboardView.schedule);
      expect(result.dueLoading, isFalse);
      expect(result.scheduleLoading, isFalse);
      expect(
        appointments.scheduleQueries.length,
        greaterThan(initialQueryCount),
      );
      for (final query in appointments.scheduleQueries.skip(
        initialQueryCount,
      )) {
        expect(query.namedArguments[#dateFrom], selectedDate);
        expect(query.namedArguments[#doctorId], workspaceStaff('doctor').id);
      }
      expect(patients.dueQueries.last.namedArguments[#date], selectedDate);
      expect(appointments.bookings, outcome == 'save' ? 1 : 0);
      expect(result.schedule, hasLength(outcome == 'save' ? 1 : 0));
      expect(result.duePatients, hasLength(outcome == 'save' ? 0 : 1));
      if (outcome == 'save') {
        expect(
          appointments.bookedSlots.single,
          selectedDate.add(const Duration(hours: 9)),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
