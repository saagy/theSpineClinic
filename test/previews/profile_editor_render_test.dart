import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import '../fixtures/profile_editor_harness.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  testWidgets('profile error and discard confirmation', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final GlobalKey key = GlobalKey();
    final repo = ProfileEditorRepository()
      ..outcome = const Result.failure(
        NetworkException(code: 'network/offline', message: 'Fixture offline'),
      );
    await pumpProfileEditor(tester, repo, captureKey: key);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Dr. Nadia Hassan',
    );
    await tester.pump();
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.errorNetworkGeneric), findsOneWidget);
    await capturePolish(tester, key, 'profile-save-error');
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capturePolish(tester, key, 'profile-discard-confirmation');
  });
  for (final double width in [390, 840, 1440]) {
    for (final bool dark in [false, true]) {
      testWidgets('profile editor $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final GlobalKey key = GlobalKey();
        await pumpProfileEditor(
          tester,
          ProfileEditorRepository(),
          captureKey: key,
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'profile-$width-$dark');
        await tester.tap(find.text(AppStrings.changePassword));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'password-$width-$dark');
      });
    }
  }
  testWidgets('narrow enlarged text and keyboard keep actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final GlobalKey key = GlobalKey();
    await pumpProfileEditor(
      tester,
      ProfileEditorRepository(),
      captureKey: key,
      scale: 2,
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'Dr. Mariam Ahmed Mohamed Abdelrahman Hassan',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capturePolish(tester, key, 'profile-320-large-text');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField).last);
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomRight(find.text(AppStrings.saveChanges)).dy,
      lessThan(460),
    );
    await capturePolish(tester, key, 'profile-320-keyboard');
  });
}
