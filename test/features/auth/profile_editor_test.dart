import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/presentation/edit_profile_screen.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_skeleton.dart';
import '../../fixtures/profile_editor_harness.dart';

void main() {
  testWidgets(
    'details have a disabled Save until edited and validate before writes',
    (tester) async {
      final repo = ProfileEditorRepository();
      await pumpProfileEditor(tester, repo);
      expect(find.text(AppStrings.personalDetails), findsOneWidget);
      expect(find.text(AppStrings.confirmPassword), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, AppStrings.saveChanges),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid@');
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.fullNameRequired), findsOneWidget);
      expect(find.text(AppStrings.emailInvalid), findsOneWidget);
      expect(repo.profileWrites, 0);
    },
  );

  testWidgets('save returns to profile with updated identity', (tester) async {
    final repo = ProfileEditorRepository();
    final router = await pumpProfileEditor(tester, repo);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Dr. Nadia Hassan',
    );
    await tester.pump();
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();
    expect(repo.profileWrites, 1);
    expect(repo.passwordWrites, 0);
    expect(repo.savedProfile!.fullName, 'Dr. Nadia Hassan');
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.doctorProfile,
    );
    expect(find.text('Dr. Nadia Hassan'), findsOneWidget);
  });

  testWidgets(
    'cancel and system back protect drafts; keep editing preserves fields',
    (tester) async {
      final repo = ProfileEditorRepository();
      final router = await pumpProfileEditor(tester, repo);
      await tester.enterText(find.byType(TextFormField).first, 'Unsaved name');
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.keepEditing));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved name'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.discardChangesMessage), findsOneWidget);
      await tester.tap(find.text(AppStrings.discard));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.doctorProfile,
      );
      expect(repo.profileWrites, 0);
    },
  );

  testWidgets('failed save keeps draft and error; retry completes', (
    tester,
  ) async {
    final repo = ProfileEditorRepository()
      ..outcome = const Result.failure(
        NetworkException(code: 'network/offline', message: 'Fixture offline'),
      );
    await pumpProfileEditor(tester, repo);
    await tester.enterText(find.byType(TextFormField).first, 'Retry this name');
    await tester.pump();
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();
    expect(find.text('Retry this name'), findsOneWidget);
    expect(find.text(AppStrings.errorNetworkGeneric), findsOneWidget);
    repo.outcome = const Result.success(null);
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();
    expect(repo.profileWrites, 2);
    expect(find.text('Retry this name'), findsOneWidget);
  });

  testWidgets('pending save prevents duplicate submission and back', (
    tester,
  ) async {
    final repo = ProfileEditorRepository()
      ..pendingWrite = Completer<Result<void>>();
    final router = await pumpProfileEditor(tester, repo);
    await tester.enterText(find.byType(TextFormField).first, 'Pending name');
    await tester.pump();
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text(AppStrings.discardChangesMessage), findsNothing);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, AppStrings.cancel),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(repo.profileWrites, 1);
    repo.pendingWrite!.complete(const Result.success(null));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.doctorProfile,
    );
  });

  testWidgets(
    'initial loading, missing session and failed load have explicit states',
    (tester) async {
      final repo = ProfileEditorRepository()..pendingLoad = Completer();
      await pumpProfileEditor(tester, repo);
      expect(find.byType(FormPageSkeleton), findsOneWidget);
      repo.pendingLoad!.complete(null);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.errorAuthSessionExpired), findsOneWidget);
      expect(find.text(AppStrings.signIn), findsOneWidget);
    },
  );

  testWidgets('load failure can retry without leaving editor', (tester) async {
    final repo = ProfileEditorRepository()..failLoad = true;
    await pumpProfileEditor(tester, repo);
    expect(find.text(AppStrings.errorNetworkGeneric), findsOneWidget);
    repo.failLoad = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.personalDetails), findsOneWidget);
  });
}
