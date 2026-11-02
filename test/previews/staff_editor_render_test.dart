import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import '../fixtures/staff_editor_harness.dart';
import '../fixtures/staff_workspace.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final double width in [390, 1440]) {
    for (final String variant in ['reception', 'self', 'inactive']) {
      testWidgets('staff $variant $width', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final GlobalKey key = GlobalKey();
        final Staff target = switch (variant) {
          'reception' => staffRoster[2],
          'inactive' => staffRoster[3],
          _ => staffAdmin,
        };
        await pumpStaffEditor(
          tester,
          StaffEditorRepository(),
          staff: target,
          captureKey: key,
        );
        await tester.ensureVisible(
          find.text(
            variant == 'reception'
                ? AppStrings.canManagePayments
                : AppStrings.changePassword,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'staff-$variant-$width');
      });
    }
  }
  testWidgets('deactivation check failure and named confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final GlobalKey key = GlobalKey();
    final repo = StaffEditorRepository()
      ..upcoming = const Result.failure(
        NetworkException(code: 'network/offline', message: 'Fixture offline'),
      );
    await pumpStaffEditor(tester, repo, captureKey: key);
    await tester.ensureVisible(find.text(AppStrings.deactivateOnSave));
    await tester.tap(find.text(AppStrings.deactivateOnSave));
    await tester.pump();
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();
    await capturePolish(tester, key, 'staff-access-check-error');
    repo.upcoming = const Result.success(3);
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await capturePolish(tester, key, 'staff-deactivation-review');
    await tester.tap(find.text(AppStrings.keepEditing));
    await tester.pumpAndSettle();
  });
  for (final double width in [390, 840, 1440]) {
    for (final bool dark in [false, true]) {
      testWidgets('staff edit $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final GlobalKey key = GlobalKey();
        await pumpStaffEditor(
          tester,
          StaffEditorRepository(),
          captureKey: key,
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'staff-$width-$dark-top');
        await tester.ensureVisible(find.text(AppStrings.changePassword));
        await tester.pumpAndSettle();
        await capturePolish(tester, key, 'staff-$width-$dark-account');
        if (!dark && width != 840) {
          await tester.tap(find.text(AppStrings.changePassword));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(AppStrings.confirmPassword));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await capturePolish(tester, key, 'staff-$width-password');
        }
      });
    }
  }
  testWidgets('staff edit narrow enlarged text and keyboard', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final GlobalKey key = GlobalKey();
    await pumpStaffEditor(
      tester,
      StaffEditorRepository(),
      captureKey: key,
      scale: 2,
    );
    await tester.ensureVisible(find.text(AppStrings.changePassword));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capturePolish(tester, key, 'staff-320-large-text');
    await tester.tap(find.text(AppStrings.changePassword));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.fields['password']!.didChange('long-password');
    await tester.pump();
    await tester.ensureVisible(find.text(AppStrings.confirmPassword));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomRight(find.text(AppStrings.saveChanges)).dy,
      lessThan(460),
    );
    await capturePolish(tester, key, 'staff-320-keyboard');
  });
}
