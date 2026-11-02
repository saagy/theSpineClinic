import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_body.dart';
import '../../fixtures/staff_editor_harness.dart';
import '../../fixtures/staff_workspace.dart';

void main() {
  testWidgets(
    'account access is staged, undoable and confirmed with appointment context',
    (tester) async {
      final repo = StaffEditorRepository();
      await pumpStaffEditor(tester, repo);
      expect(find.text(AppStrings.accountEnabled), findsNothing);
      await tester.ensureVisible(find.text(AppStrings.deactivateOnSave));
      await tester.tap(find.text(AppStrings.deactivateOnSave));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(
        find.text(AppStrings.staffAccessStatus(AppStrings.staffWillDeactivate)),
        findsOneWidget,
      );
      await tester.tap(find.text(AppStrings.undoAccessChange));
      await tester.pumpAndSettle();
      final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
      expect(form.fields['is_active']!.value, isTrue);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text(AppStrings.deactivateOnSave));
      await tester.pump();
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.deactivateStaffWarning(3)), findsOneWidget);
      expect(repo.writes, 0);
      await tester.tap(find.text(AppStrings.deactivateAccount).last);
      await tester.pumpAndSettle();
      expect(repo.writes, 1);
      expect(repo.submitted!.isActive, isFalse);
      expect(repo.countCalls, 1);
    },
  );
  testWidgets(
    'failed deactivation check cannot silently become zero appointments',
    (tester) async {
      final repo = StaffEditorRepository()
        ..upcoming = const Result.failure(
          NetworkException(
            code: 'network/offline',
            message: 'Internal diagnostic',
          ),
        );
      await pumpStaffEditor(tester, repo);
      await tester.ensureVisible(find.text(AppStrings.deactivateOnSave));
      await tester.tap(find.text(AppStrings.deactivateOnSave));
      await tester.pump();
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(find.text(AppStrings.errorNetworkGeneric), findsOneWidget);
      expect(find.text('Internal diagnostic'), findsNothing);
      expect(find.text(AppStrings.undoAccessChange), findsOneWidget);
    },
  );
  testWidgets(
    'password action opens a draft; cancel clears it without losing contact edits',
    (tester) async {
      final repo = StaffEditorRepository();
      await pumpStaffEditor(tester, repo);
      final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
      form.fields['full_name']!.didChange('Changed name');
      await tester.ensureVisible(find.text(AppStrings.changePassword));
      await tester.tap(find.text(AppStrings.changePassword));
      await tester.pumpAndSettle();
      form.fields['password']!.didChange('new-password');
      form.fields['confirm_password']!.didChange('new-password');
      await tester.ensureVisible(find.text(AppStrings.cancelPasswordChange));
      await tester.tap(find.text(AppStrings.cancelPasswordChange));
      await tester.pumpAndSettle();
      expect(form.fields.containsKey('password'), isFalse);
      expect(form.fields['change_password']!.value, isFalse);
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(repo.submitted!.fullName, 'Changed name');
      expect(repo.password, isNull);
    },
  );
  testWidgets(
    'new password validates and is submitted with the complete staff draft',
    (tester) async {
      final repo = StaffEditorRepository();
      await pumpStaffEditor(tester, repo);
      final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
      await tester.ensureVisible(find.text(AppStrings.changePassword));
      await tester.tap(find.text(AppStrings.changePassword));
      await tester.pumpAndSettle();
      form.fields['password']!.didChange('short');
      form.fields['confirm_password']!.didChange('different');
      await tester.pump();
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(find.text(AppStrings.passwordMinLength), findsOneWidget);
      expect(find.text(AppStrings.passwordsDoNotMatch), findsOneWidget);
      form.fields['password']!.didChange(' new password ');
      form.fields['confirm_password']!.didChange(' new password ');
      await tester.pump();
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(repo.password, ' new password ');
      expect(repo.submitted!.id, staffRoster[1].id);
    },
  );
  testWidgets(
    'cancel and system back protect drafts and failure retains recoverable values',
    (tester) async {
      final repo = StaffEditorRepository()
        ..outcome = const Result.failure(
          NetworkException(
            code: 'network/offline',
            message: 'Internal failure',
          ),
        );
      await pumpStaffEditor(tester, repo);
      final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
      form.fields['full_name']!.didChange('Retain me');
      await tester.pump();
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.errorNetworkGeneric), findsOneWidget);
      expect(form.fields['full_name']!.value, 'Retain me');
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.keepEditing));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.discard));
      await tester.pumpAndSettle();
      expect(find.byType(StaffFormBody), findsNothing);
      expect(repo.writes, 1);
    },
  );
  testWidgets(
    'self role and activation are explained without editable account controls',
    (tester) async {
      await pumpStaffEditor(tester, StaffEditorRepository(), staff: staffAdmin);
      expect(find.text(AppStrings.staffOwnRoleHelp), findsOneWidget);
      expect(find.text(AppStrings.staffOwnAccessHelp), findsOneWidget);
      expect(find.text(AppStrings.deactivateOnSave), findsNothing);
    },
  );
}
