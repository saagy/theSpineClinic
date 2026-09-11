import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart' as repository;
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';

class _DelayedRepository implements AppointmentRepository {
  final count = Completer<Result<int>>();
  final page = Completer<Result<List<AppointmentWithPatient>>>();
  int pageCalls = 0;

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #countAppointmentsForPatient) return count.future;
    if (invocation.memberName == #getAppointmentsForPatientPaginated) {
      pageCalls++;
      return page.future;
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  for (final duringCount in [true, false]) {
    test('disposal during ${duringCount ? 'count' : 'page'} ignores the response', () async {
      final repo = _DelayedRepository();
      final container = ProviderContainer(overrides: [
        repository.appointmentRepositoryProvider.overrideWithValue(repo),
      ]);
      final subscription = container.listen(patientAppointmentsProvider('patient'), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      if (!duringCount) {
        repo.count.complete(const Result.success(1));
        await Future<void>.delayed(Duration.zero);
        expect(repo.pageCalls, 1);
      }
      subscription.close();
      container.dispose();
      if (duringCount) {
        repo.count.complete(const Result.success(1));
      } else {
        repo.page.complete(const Result.success([]));
      }
      await Future<void>.delayed(Duration.zero);
      expect(repo.pageCalls, duringCount ? 0 : 1);
    });
  }

  test('filter debounce does not run after disposal', () async {
    final repo = _DelayedRepository();
    final container = ProviderContainer(overrides: [
      repository.appointmentRepositoryProvider.overrideWithValue(repo),
    ]);
    container.listen(patientAppointmentsProvider('patient'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    container.read(patientAppointmentsProvider('patient').notifier).setDoctorFilter('doctor');
    container.dispose();
    repo.count.complete(const Result.success(0));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(repo.pageCalls, 0);
  });
}
