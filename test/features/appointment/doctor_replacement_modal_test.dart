import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/bulk_doctor_replacement_result.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_modal.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

void main() {
  testWidgets('replacement preselects all and submits the chosen subset', (
    tester,
  ) async {
    List<String>? submittedDoctors;
    List<String>? submittedAppointments;
    final Patient patient = _patient();
    final List<AppointmentWithPatient> appointments = [
      _appointment('appointment-1', patient, 9),
      _appointment('appointment-2', patient, 10),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: DoctorReplacementModal(
          absentDoctor: _doctor('absent', 'Dr Absent'),
          availableDoctors: [_doctor('replacement', 'Dr Replacement')],
          appointments: appointments,
          day: DateTime(2026, 7, 14),
          onSubmit: (doctorIds, appointmentIds) async {
            submittedDoctors = doctorIds;
            submittedAppointments = appointmentIds;
            return const Result.success(
              BulkDoctorReplacementResult(replacedCount: 1, remainingCount: 1),
            );
          },
        ),
      ),
    );

    final List<Checkbox> initial = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .toList();
    expect(initial, hasLength(3));
    expect(initial.every((checkbox) => checkbox.value == true), isTrue);

    await tester.tap(find.text(AppStrings.selectReplacementDoctors));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dr Replacement'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    await tester.tap(find.text(AppStrings.replaceOnAppointments(1)));
    await tester.pumpAndSettle();

    expect(submittedDoctors, ['replacement']);
    expect(submittedAppointments, ['appointment-1']);
    expect(tester.takeException(), isNull);
  });
}

Staff _doctor(String id, String name) => Staff(
  id: id,
  fullName: name,
  email: '$id@clinic.test',
  role: UserRole.doctor,
  branch: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
);

Patient _patient() => Patient(
  id: 'patient-1',
  fullName: 'Mariam Hassan',
  phoneNumber: '01000000000',
  clinic: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
);

AppointmentWithPatient _appointment(String id, Patient patient, int hour) {
  return AppointmentWithPatient(
    appointment: Appointment(
      id: id,
      patientId: patient.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: DateTime(2026, 7, 14, hour),
      createdAt: DateTime(2026),
    ),
    patient: patient,
  );
}
