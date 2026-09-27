import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_tab.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

import '../../fixtures/workspace_data.dart';

class _TestUser extends CurrentUser {
  @override
  Future<Staff?> build() async => workspaceStaff('reception');
}

class _TestBranch extends ActiveBranch {
  @override
  ClinicLocation build() => ClinicLocation.tagamoa;
}

class _PendingScheduleRepo implements AppointmentRepository {
  final List<Completer<Result<List<AppointmentWithPatient>>>> pending = [];

  @override
  Future<Result<List<AppointmentWithPatient>>> noSuchMethod(Invocation call) {
    if ((call.namedArguments[#offset] as int? ?? 0) > 0) {
      return Future.value(const Result.success([]));
    }
    final request = Completer<Result<List<AppointmentWithPatient>>>();
    pending.add(request);
    return request.future;
  }
}

Future<void> _settle(ProviderContainer container) async {
  await container.pump();
  await Future<void>.delayed(Duration.zero);
  await container.pump();
}

void main() {
  testWidgets('agenda replaces empty state immediately with week skeleton', (
    WidgetTester tester,
  ) async {
    final DateTime today = DateTime.now();
    await tester.pumpWidget(
      _agenda(
        ReceptionistAppointmentsState(selectedDate: today, loading: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noAppointments), findsOneWidget);

    await tester.pumpWidget(
      _agenda(
        ReceptionistAppointmentsState(
          selectedDate: today.add(const Duration(days: 21)),
          loading: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SkeletonTileList), findsOneWidget);
    expect(find.text(AppStrings.noAppointments), findsNothing);

    await tester.pumpWidget(
      _agenda(
        ReceptionistAppointmentsState(
          selectedDate: today.add(const Duration(days: 21)),
          loading: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.noAppointments), findsOneWidget);
  });

  for (final bool doctor in <bool>[false, true]) {
    test(
      'uncached ${doctor ? 'doctor' : 'reception'} week loads before empty',
      () async {
        final repo = _PendingScheduleRepo();
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(_TestUser.new),
            activeBranchProvider.overrideWith(_TestBranch.new),
            appointmentRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);
        if (doctor) {
          container.listen(doctorScheduleProvider, (_, _) {});
        } else {
          container.listen(receptionistAppointmentsProvider, (_, _) {});
        }
        await _settle(container);

        final DateTime today = DateTime.now();
        final booked = AppointmentWithPatient(
          patient: workspacePatient,
          appointment: Appointment(
            id: 'existing',
            patientId: workspacePatient.id,
            type: AppointmentType.normalPtSession,
            scheduledAt: today,
            createdAt: today,
          ),
        );
        repo.pending.last.complete(Result.success([booked]));
        await _settle(container);

        final DateTime nextWeek = today.add(const Duration(days: 21));
        if (doctor) {
          expect(container.read(doctorScheduleProvider).allItems, isNotEmpty);
          container.read(doctorScheduleProvider.notifier).selectDate(nextWeek);
          final state = container.read(doctorScheduleProvider);
          expect(state.loading, isTrue);
          expect(state.allItems, isEmpty);
        } else {
          expect(
            container.read(receptionistAppointmentsProvider).allItems,
            isNotEmpty,
          );
          container
              .read(receptionistAppointmentsProvider.notifier)
              .selectDate(nextWeek);
          final state = container.read(receptionistAppointmentsProvider);
          expect(state.loading, isTrue);
          expect(state.allItems, isEmpty);
        }

        repo.pending.last.complete(const Result.success([]));
        await _settle(container);
        if (doctor) {
          final state = container.read(doctorScheduleProvider);
          expect(state.loading, isFalse);
          expect(state.itemsForSelectedDay, isEmpty);
        } else {
          final state = container.read(receptionistAppointmentsProvider);
          expect(state.loading, isFalse);
          expect(state.itemsForSelectedDay, isEmpty);
        }
      },
    );
  }
}

Widget _agenda(ReceptionistAppointmentsState state) => ProviderScope(
  overrides: [currentUserProvider.overrideWith(_TestUser.new)],
  child: MaterialApp(
    home: Scaffold(
      body: ReceptionistTodayTab(
        state: state,
        searchQuery: '',
        onSearchChanged: (_) {},
        onRefresh: () {},
        onStatusChanged: () {},
      ),
    ),
  ),
);
