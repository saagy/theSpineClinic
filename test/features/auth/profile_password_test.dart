import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import '../../fixtures/profile_editor_harness.dart';

void main() {
  testWidgets(
    'password step preserves contact draft and never saves profile fields',
    (tester) async {
      final repo = ProfileEditorRepository();
      await pumpProfileEditor(tester, repo);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Unsaved contact draft',
      );
      await tester.ensureVisible(find.text(AppStrings.changePassword));
      await tester.tap(find.text(AppStrings.changePassword));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text(AppStrings.personalDetails), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        ' new password ',
      );
      await tester.enterText(find.byType(TextFormField).last, ' new password ');
      await tester.tap(find.text(AppStrings.updatePassword));
      await tester.pumpAndSettle();
      expect(repo.passwordWrites, 1);
      expect(repo.savedPassword, ' new password ');
      expect(repo.profileWrites, 0);
      expect(find.text('Unsaved contact draft'), findsOneWidget);
    },
  );

  testWidgets(
    'password length, confirmation and visibility work before submission',
    (tester) async {
      final repo = ProfileEditorRepository();
      await pumpProfileEditor(tester, repo, passwordOnly: true);
      await tester.enterText(find.byType(TextFormField).first, 'short');
      await tester.enterText(find.byType(TextFormField).last, 'different');
      await tester.tap(find.text(AppStrings.updatePassword));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.passwordMinLength), findsOneWidget);
      expect(find.text(AppStrings.passwordsDoNotMatch), findsOneWidget);
      await tester.tap(find.byTooltip(AppStrings.showPassword).first);
      await tester.pump();
      expect(find.byTooltip(AppStrings.hidePassword), findsOneWidget);
      expect(repo.passwordWrites, 0);
    },
  );

  testWidgets('failed password change retains fields and offers a retry', (
    tester,
  ) async {
    final repo = ProfileEditorRepository()
      ..outcome = const Result.failure(
        NetworkException(code: 'network/offline', message: 'Fixture offline'),
      );
    await pumpProfileEditor(tester, repo, passwordOnly: true);
    await tester.enterText(find.byType(TextFormField).first, 'test-password');
    await tester.enterText(find.byType(TextFormField).last, 'test-password');
    await tester.tap(find.text(AppStrings.updatePassword));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.errorNetworkGeneric), findsOneWidget);
    expect(repo.profileWrites, 0);
    repo.outcome = const Result.success(null);
    await tester.tap(find.text(AppStrings.updatePassword));
    await tester.pumpAndSettle();
    expect(repo.passwordWrites, 2);
  });
}
