import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import '../../fixtures/workspace_data.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

class _Doctor extends CurrentUser {
  @override
  Future<Staff?> build() async => workspaceStaff('doctor');
}

base class _Failures extends ProviderObserver {
  final errors = <Object>[];
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    errors.add(error);
  }
}

void main() {
  for (final editing in [false, true]) {
    test(
      'leaving appointment while permission lookup is pending, editing=$editing',
      () async {
        final assigned = Completer<List<Staff>>();
        final failures = _Failures();
        final container = ProviderContainer(
          observers: [failures],
          overrides: [
            currentUserProvider.overrideWith(_Doctor.new),
            patientAssignedDoctorsProvider(
              'patient',
            ).overrideWith((ref) => assigned.future),
          ],
        );
        addTearDown(container.dispose);
        await container.read(currentUserProvider.future);
        final provider = editing
            ? canEditAppointmentProvider(
                appointmentId: 'appointment',
                patientId: 'patient',
              )
            : canAccessAppointmentProvider(
                appointmentId: 'appointment',
                patientId: 'patient',
              );
        final subscription = container.listen(provider, (_, _) {});
        await container.pump();
        subscription.close();
        await container.pump();
        assigned.complete([]);
        await container.pump();
        expect(failures.errors, isEmpty);
      },
    );
  }
}
