import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/agenda_status_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_action_buttons.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import '../../fixtures/workspace_data.dart';

class _InsufficientBalanceController extends AgendaStatusController {
  @override
  AgendaStatusState build(String appointmentId) => const AgendaStatusState();

  @override
  Future<Result<void>?> update(String patientId, AppointmentStatus status) async =>
      const Failure<void>(DatabaseException(
        code: 'db/insufficient-package-balance',
        message: 'Insufficient package balance',
        userMessageKey: 'insufficient_package_balance',
      ));
}

final _appointment = Appointment(
  id: 'appointment',
  patientId: workspacePatient.id,
  type: AppointmentType.normalPtSession,
  scheduledAt: DateTime(2026, 9, 22),
  createdAt: DateTime(2026, 9, 22),
);

void main() {
  testWidgets('detail check-in shows the package failure and stays scheduled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agendaStatusControllerProvider(_appointment.id).overrideWith(
            _InsufficientBalanceController.new,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentActionButtons(
              appointment: _appointment,
              userRole: UserRole.receptionist,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.checkIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.insufficientPackageBalance), findsOneWidget);
    expect(find.text(AppStrings.statusUpdateError), findsNothing);
    expect(find.text(AppStrings.checkIn), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
