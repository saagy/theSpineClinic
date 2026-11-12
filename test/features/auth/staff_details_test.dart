import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_schedule_label.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import '../../fixtures/staff_editor_harness.dart';
import '../../fixtures/staff_workspace.dart';

const t = AppStrings.staffDetails;

final saved = StaffDetails(
  nationalId: '29001011234567',
  birthDate: DateTime(1990, 1, 1),
  hireDate: DateTime(2024, 3, 1),
  workingDays: const [7, 6, 1, 2, 3, 4],
  workStartMinutes: 9 * 60,
  workEndMinutes: 17 * 60,
);

Finder field(String label) => find.descendant(
  of: find.widgetWithText(LabeledFormField, label),
  matching: find.byType(TextField),
);

FormBuilderState form(WidgetTester tester) =>
    tester.state<FormBuilderState>(find.byType(FormBuilder));

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
    expect(json, {
      'national_id': '29001011234567',
      'birth_date': '1990-01-01',
      'hire_date': '2024-03-01',
      'working_days': [1, 2, 3, 4, 6, 7],
      'work_starts_at': '09:00',
      'work_ends_at': '17:00',
    });
    final read = StaffDetails.fromJson({
      ...json,
      'work_starts_at': '09:00:00',
      'work_ends_at': '17:00:00',
    });
    expect(read, saved);
    expect(read.workingDaysInWeekOrder, [6, 7, 1, 2, 3, 4]);
    expect(StaffDetails.empty.isEmpty, isTrue);
    expect(StaffDetails.empty.toJson()['national_id'], '');
    expect(StaffDetails(workingDays: const [3, 3, 1]).workingDays, [1, 3]);
  });

  testWidgets('directory schedule reads as ranges and hours', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) => const SizedBox())));
    context = tester.element(find.byType(SizedBox));
    expect(staffScheduleLabel(context, saved), 'Sat–Thu · 9:00 AM – 5:00 PM');
    expect(staffScheduleLabel(context, StaffDetails(workingDays: const [6, 1, 3])), 'Sat, Mon, Wed');
    expect(staffScheduleLabel(context, StaffDetails(workingDays: const [1, 2, 3, 4, 5, 6, 7])), t.everyDay);
    expect(staffScheduleLabel(context, StaffDetails(workingDays: const [7, 1, 2, 5])), 'Sun–Tue, Fri');
    expect(staffScheduleLabel(context, StaffDetails.empty), isNull);
    expect(staffScheduleLabel(context, null), isNull);
  });

  testWidgets('the editor opens with saved details and leaves them alone', (tester) async {
    final repo = StaffEditorRepository()..details = saved;
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    expect(repo.detailsReads, 1);
    expect(find.text('29001011234567'), findsOneWidget);
    expect(find.text('Jan 1, 1990'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    await tester.enterText(field(AppStrings.fullName), 'Dr Renamed');
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 1);
    expect(repo.submittedDetails, isNull);
  });

  testWidgets('changed details are saved with the profile', (tester) async {
    final repo = StaffEditorRepository()..details = saved;
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    await tester.ensureVisible(find.text(t.weekday(5)));
    await tester.tap(find.text(t.weekday(5)));
    await tester.tap(find.text(t.weekday(7)));
    await tester.pump();
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 1);
    expect(repo.submittedDetails!.workingDays, [1, 2, 3, 4, 5, 6]);
    expect(repo.submittedDetails!.nationalId, saved.nationalId);
  });

  testWidgets('toggling a day back leaves the form unchanged', (tester) async {
    final repo = StaffEditorRepository()..details = saved;
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    await tester.ensureVisible(find.text(t.weekday(5)));
    await tester.tap(find.text(t.weekday(5)));
    await tester.pump();
    await tester.tap(find.text(t.weekday(5)));
    await tester.pumpAndSettle();
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(of: find.text(AppStrings.saveChanges).last, matching: find.bySubtype<ButtonStyleButton>()),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('invalid national ID and hours block the save', (tester) async {
    final repo = StaffEditorRepository();
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    await tester.enterText(field(t.nationalId), '12345abc');
    await tester.pump();
    expect(find.text('12345'), findsOneWidget);
    form(tester).fields['work_starts_at']!.didChange(17 * 60);
    form(tester).fields['work_ends_at']!.didChange(9 * 60);
    await tester.pump();
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 0);
    expect(find.text(t.nationalIdInvalid), findsOneWidget);
    expect(find.text(t.hoursOrder), findsOneWidget);
    form(tester).fields['work_ends_at']!.didChange(null);
    await tester.pump();
    form(tester).fields['work_ends_at']!.validate();
    await tester.pump();
    expect(find.text(t.hoursBoth), findsOneWidget);
  });

  testWidgets('a start time alone is only flagged on save, under the end time', (tester) async {
    final repo = StaffEditorRepository();
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    form(tester).fields['work_starts_at']!.didChange(9 * 60);
    await tester.pumpAndSettle();
    expect(find.text(t.hoursBoth), findsNothing);
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 0);
    expect(find.text(t.hoursBoth), findsOneWidget);
    form(tester).fields['work_ends_at']!.didChange(17 * 60);
    await tester.pumpAndSettle();
    expect(find.text(t.hoursBoth), findsNothing);
  });

  testWidgets('a hire date before the birth date is rejected', (tester) async {
    final repo = StaffEditorRepository()..details = saved;
    await pumpStaffEditor(tester, repo, staff: staffRoster[1]);
    form(tester).fields['hire_date']!.didChange(DateTime(1980, 1, 1));
    await tester.pump();
    await save(tester, AppStrings.saveChanges);
    expect(repo.writes, 0);
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

  testWidgets('new staff send details only when some were entered', (tester) async {
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
    expect(repo.submittedDetails!.workingDays, isEmpty);
  });
}
