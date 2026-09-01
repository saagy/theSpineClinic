import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/nav_tabs.dart';

void main() {
  test('Clinic Admin navigation excludes doctor identity tabs', () {
    final tabs = NavTabs.forRole('super_admin');

    expect(tabs.map((tab) => tab.label), [
      AppStrings.navAppts,
      AppStrings.patients,
      AppStrings.navAnalytics,
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
