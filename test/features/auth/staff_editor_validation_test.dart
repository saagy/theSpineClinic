import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import '../../fixtures/staff_editor_harness.dart';

void main() {
  testWidgets('corrected identity and role clear errors without another Save', (
    tester,
  ) async {
    final repo = StaffEditorRepository();
    await pumpStaffEditor(tester, repo, create: true);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.addStaff));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.fullNameRequired), findsOneWidget);
    expect(find.text(AppStrings.roleRequired), findsOneWidget);
    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.fields['full_name']!.didChange('New Doctor');
    form.fields['email']!.didChange('new@example.invalid');
    await tester.pumpAndSettle();
    final role = find.byType(FormBuilderDropdown<UserRole>);
    await tester.ensureVisible(role);
    await tester.tap(role);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.doctor).last);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.fullNameRequired), findsNothing);
    expect(find.text(AppStrings.emailRequired), findsNothing);
    expect(find.text(AppStrings.roleRequired), findsNothing);
    expect(repo.writes, 0);
  });

  testWidgets(
    'password corrections clear errors and recheck dependent confirmation',
    (tester) async {
      final repo = StaffEditorRepository();
      await pumpStaffEditor(tester, repo);
      await tester.ensureVisible(find.text(AppStrings.changePassword));
      await tester.tap(find.text(AppStrings.changePassword));
      await tester.pumpAndSettle();
      final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
      form.fields['password']!.didChange('short');
      form.fields['confirm_password']!.didChange('different');
      await tester.pump();
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.passwordMinLength), findsOneWidget);
      expect(find.text(AppStrings.passwordsDoNotMatch), findsOneWidget);
      form.fields['password']!.didChange('new-password');
      form.fields['confirm_password']!.didChange('new-password');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.passwordMinLength), findsNothing);
      expect(find.text(AppStrings.passwordsDoNotMatch), findsNothing);
      form.fields['password']!.didChange('another-password');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.passwordsDoNotMatch), findsOneWidget);
      form.fields['confirm_password']!.didChange('another-password');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.passwordsDoNotMatch), findsNothing);
      expect(repo.writes, 0);
    },
  );
}
