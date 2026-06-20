import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';

void main() {
  group('AppointmentType redesign invariants', () {
    test('all new enum members exist', () {
      expect(AppointmentType.values, contains(AppointmentType.normalPtSession));
      expect(AppointmentType.values, contains(AppointmentType.spinalTractionSession));
      expect(AppointmentType.values, contains(AppointmentType.initialAssessment));
      expect(AppointmentType.values, contains(AppointmentType.reassessment));
    });

    test('database strings are snake_case and stable', () {
      expect(AppointmentType.normalPtSession.dbValue, 'normal_pt_session');
      expect(AppointmentType.spinalTractionSession.dbValue, 'spinal_traction_session');
      expect(AppointmentType.initialAssessment.dbValue, 'initial_assessment');
      expect(AppointmentType.reassessment.dbValue, 'reassessment');
    });

    test('assessment types never affect package balance', () {
      expect(AppointmentType.initialAssessment.affectsPackageBalance, isFalse);
      expect(AppointmentType.reassessment.affectsPackageBalance, isFalse);
    });

    test('session types affect their corresponding bucket', () {
      expect(AppointmentType.normalPtSession.affectsPackageBalance, isTrue);
      expect(AppointmentType.spinalTractionSession.affectsPackageBalance, isTrue);
    });

    test('display labels come from AppStrings', () {
      expect(AppointmentType.initialAssessment.displayLabel,
          AppStrings.initialAssessment);
      expect(AppointmentType.reassessment.displayLabel, AppStrings.reassessment);
      expect(AppointmentType.normalPtSession.displayLabel,
          AppStrings.normalPtSession);
      expect(AppointmentType.spinalTractionSession.displayLabel,
          AppStrings.spinalTractionSession);
    });
  });
}
