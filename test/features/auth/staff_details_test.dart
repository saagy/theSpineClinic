import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../../fixtures/staff_branches_fixture.dart';
import '../../fixtures/staff_editor_harness.dart';
import '../../fixtures/staff_workspace.dart';

const t = AppStrings.staffDetails;
const s = AppStrings.staffSchedule;

final saved = StaffDetails(
  nationalId: '29001011234567',
  birthDate: DateTime(1990, 1, 1),
  hireDate: DateTime(2024, 3, 1),
);

Finder field(String label) => find.descendant(
  of: find.widgetWithText(LabeledFormField, label),
  matching: find.byType(TextField),
);

FormBuilderState form(WidgetTester tester) => tester.state<FormBuilderState>(find.byType(FormBuilder));

Future<void> save(WidgetTester tester, String label) async {
  await tester.pumpAndSettle();
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  test('details round-trip in the database shape', () {
    final json = saved.toJson();
    expect(json, {'national_id': '29001011234567', 'birth_date': '1990-01-01', 'hire_date': '2024-03-01'});
    final read = StaffDetails.fromJson({...json, 'updated_at': '2026-11-14T10:00:00Z', 'updated_by': 'admin'});
    expect(read, saved);
    expect(read.updatedById, 'admin');
    expect(StaffDetails.empty.isEmpty, isTrue);
    expect(StaffDetails.empty.toJson()['national_id'], '');
  });

  testWidgets('the editor opens with saved details and schedule and leaves them alone', (tester) async {
    final repo = StaffEditorRepository()
      ..details = saved
      ..assignments = demoAssignments;
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    expect(repo.detailsReads, 1);
    expect(find.text('29001011234567'), findsOneWidget);
    expect(find.text('Jan 1, 1990'), findsOneWidget);
    expect(find.textContaining('Tagamoa · 10:00 AM – 2:00 PM'), findsOneWidget);
    await tester.enterText(field(AppStrings.fullName), 'Dr Renamed');
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 1);
    expect(repo.submittedDetails, isNull);
    expect(repo.submittedSchedule, isNull);
  });

  testWidgets('adding a branch saves branches and shifts with the profile', (tester) async {
    final repo = StaffEditorRepository()..assignments = demoAssignments;
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    await tester.ensureVisible(find.text(ClinicLocation.masrElgedida.displayLabel));
    await tester.tap(find.text(ClinicLocation.masrElgedida.displayLabel));
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 1);
    expect(repo.submittedSchedule!.branches, ClinicLocation.values);
    expect(repo.submittedSchedule!.shifts, demoAssignments.shiftsOf('doctor'));
  });

  testWidgets('removing a doctor\'s branch with upcoming visits asks first', (tester) async {
    final repo = StaffEditorRepository()
      ..assignments = demoAssignments
      ..upcomingAt = {ClinicLocation.madinaty: 4};
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    await tester.ensureVisible(find.text(ClinicLocation.madinaty.displayLabel).first);
    await tester.tap(find.text(ClinicLocation.madinaty.displayLabel).first);
    await save(tester, AppStrings.saveChanges);
    expect(find.text(s.removeBranchTitle), findsOneWidget);
    expect(find.textContaining('4 upcoming visits at Madinaty'), findsOneWidget);
    await tester.tap(find.text(s.keepBranch));
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    await save(tester, AppStrings.saveChanges);
    await tester.tap(find.text(s.removeBranchConfirm));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(repo.submittedSchedule!.branches, [ClinicLocation.tagamoa]);
    expect(repo.submittedSchedule!.shifts.every((x) => x.branch == ClinicLocation.tagamoa), isTrue);
  });

  testWidgets('a receptionist needs at least one branch', (tester) async {
    final repo = StaffEditorRepository();
    await pumpStaffEditor(tester, repo, staff: staffRoster[2]);
    await save(tester, AppStrings.saveChanges);
    form(tester).fields['full_name']!.didChange('Nour M');
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 0);
    expect(find.text(s.receptionistNeedsBranch), findsOneWidget);
  });

  testWidgets('an invalid national ID and a hire date before birth block the save', (tester) async {
    final repo = StaffEditorRepository()..details = saved;
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    await tester.enterText(field(t.nationalId), '12345abc');
    await tester.pump();
    expect(find.text('12345'), findsOneWidget);
    form(tester).fields['hire_date']!.didChange(DateTime(1980, 1, 1));
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 0);
    expect(find.text(t.nationalIdInvalid), findsOneWidget);
    expect(find.text(t.hireBeforeBirth), findsOneWidget);
  });

  testWidgets('a failed load offers retry instead of an empty form', (tester) async {
    final repo = StaffEditorRepository()
      ..detailsResult = const Result.failure(DatabaseException(code: 'db/unknown', message: 'failed'));
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    expect(find.text(AppStrings.saveChanges), findsNothing);
    expect(find.text(AppStrings.retry), findsOneWidget);
    repo.detailsResult = null;
    repo.details = saved;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text('29001011234567'), findsOneWidget);
  });

  testWidgets('new staff send details and branches only when entered', (tester) async {
    final repo = StaffEditorRepository();
    await pumpStaffEditor(tester, repo, create: true);
    expect(repo.detailsReads, 0);
    final values = form(tester);
    values.fields['full_name']!.didChange('Hana Farouk');
    values.fields['email']!.didChange('hana@example.invalid');
    values.fields['role']!.didChange(UserRole.doctor);
    await tester.pumpAndSettle();
    values.fields['password']!.didChange('test-password');
    values.fields['confirm_password']!.didChange('test-password');
    await tester.enterText(field(t.nationalId), '29505051234567');
    await save(tester, AppStrings.addStaff);
    expect(repo.writes, 1);
    expect(repo.submittedDetails!.nationalId, '29505051234567');
    expect(repo.submittedSchedule, isNull);
  });

  test('a new receptionist starts at their first branch', () {
    final StaffSchedule schedule = StaffSchedule(branches: [ClinicLocation.madinaty, ClinicLocation.tagamoa]);
    expect(schedule.branches, [ClinicLocation.tagamoa, ClinicLocation.madinaty]);
  });
}
