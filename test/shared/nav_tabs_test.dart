import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/shared/widgets/nav_tabs.dart';

void main() {
  test(
    'payment receptionist Billing sits before Profile and routes by path',
    () {
      final tabs = NavTabs.forRole('receptionist', showBilling: true);
      expect(tabs.map((tab) => tab.path), [
        AppRoutes.allAppointments,
        AppRoutes.patientList,
        AppRoutes.billing,
        AppRoutes.receptionistProfile,
      ]);
      for (final role in ['doctor', 'senior_doctor', 'super_admin']) {
        expect(
          NavTabs.forRole(role, showBilling: true).map((tab) => tab.path),
          isNot(contains(AppRoutes.billing)),
        );
      }
    },
  );
  test('Clinic Admin navigation excludes doctor identity tabs', () {
    final tabs = NavTabs.forRole('super_admin');
    expect(
      tabs.map((tab) => tab.label),
      isNot(contains(AppStrings.navAnalytics)),
    );

    expect(tabs.map((tab) => tab.label), [
      AppStrings.navAppts,
      AppStrings.patients,
      AppStrings.navAdmin,
    ]);
    expect(
      tabs.map((tab) => tab.label),
      isNot(contains(AppStrings.navMySchedule)),
    );
    expect(
      tabs.map((tab) => tab.label),
      isNot(contains(AppStrings.navMyPatients)),
    );
  });

  test('doctor navigation keeps schedule and assigned patients', () {
    expect(NavTabs.forRole('doctor').map((tab) => tab.label), [
      AppStrings.navMySchedule,
      AppStrings.navMyPatients,
      AppStrings.profile,
    ]);
  });

  test('senior doctor navigation shows all patients', () {
    expect(NavTabs.forRole('senior_doctor').map((tab) => tab.label), [
      AppStrings.navMySchedule,
      AppStrings.patients,
      AppStrings.profile,
    ]);
  });

  test('receptionist navigation shows appts, patients, profile', () {
    expect(NavTabs.forRole('receptionist').map((tab) => tab.label), [
      AppStrings.navAppts,
      AppStrings.patients,
      AppStrings.profile,
    ]);
  });
}
