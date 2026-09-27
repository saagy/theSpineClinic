import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/core/network/pending_mutation.dart';
import 'package:spine_clinic_app/features/appointment/presentation/pending_booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import '../../fixtures/workspace_data.dart';

class _User extends CurrentUser {
  _User(this.role);
  final String role;
  @override
  Future<Staff?> build() async =>
      workspaceStaff(role).copyWith(userId: 'test-actor');
}

class _Repository implements AppointmentRepository {
  final calls = <Invocation>[];
  @override
  Future<Result<void>> noSuchMethod(Invocation invocation) async {
    calls.add(invocation);
    return const Result.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'pending booking state survives provider recreation and clears after confirmation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final pending = await PendingMutation.open(
        actor: 'test-actor',
        scope: 'booking:patient',
        payload: {},
      );
      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWith(() => _User('reception'))],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      expect(
        await container.read(pendingBookingProvider('patient').future),
        true,
      );
      await pending.clear();
      container.invalidate(pendingBookingProvider('patient'));
      expect(
        await container.read(pendingBookingProvider('patient').future),
        false,
      );
    },
  );

  for (final role in ['reception', 'senior', 'doctor']) {
    test('$role booking permissions and atomic companion submission', () async {
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => _User(role)),
          appointmentRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      final result = await container
          .read(bookingControllerProvider.notifier)
          .executeBooking(
            patientId: 'patient',
            type: AppointmentType.normalPtSession,
            slots: [DateTime(2026, 10, 2)],
            time: const TimeOfDay(hour: 12, minute: 0),
            doctors: [workspaceStaff('doctor')],
            usePackage: false,
            companionType: AppointmentType.initialAssessment,
            companionTime: const TimeOfDay(hour: 13, minute: 30),
            companionDoctors: [workspaceStaff('senior')],
          );
      if (role == 'doctor') {
        expect(result.isFailure, true);
        expect(repository.calls, isEmpty);
      } else {
        expect(result.isSuccess, true);
        expect(repository.calls, hasLength(1));
        final call = repository.calls.single;
        expect(call.memberName, #createRecurringBookings);
        expect(call.namedArguments[#slots], [DateTime(2026, 10, 2, 12)]);
        final companion = call.namedArguments[#companion] as BookingCompanion;
        expect(companion.type, AppointmentType.initialAssessment);
        expect(companion.slots, [DateTime(2026, 10, 2, 13, 30)]);
      }
    });
  }
}
