import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import '../fixtures/program_ux_harness.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [320.0, 390.0, 768.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets('program actions at $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final programs = ProgramUxRepository();
        final key = GlobalKey();
        await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs), dark: dark, captureKey: key));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final suffix = '$width-${dark ? 'dark' : 'light'}';
        await capturePolish(tester, key, 'program-$suffix');
        await tester.tap(find.byTooltip(AppStrings.changeProgramStatus));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'program-status-$suffix');
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(AppStrings.planActions));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'program-plan-menu-$suffix');
        await tester.tap(find.text(AppStrings.createTreatmentPlan));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'program-new-plan-$suffix');
        await tester.tap(find.text(AppStrings.cancel));
        await tester.pumpAndSettle();
      });
    }
  }
  for (final list in [false, true]) {
    testWidgets('enlarged text fits phone ${list ? 'list' : 'detail'}', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final programs = ProgramUxRepository();
      programs.program = programs.program!.copyWith(
        treatmentPlans: [
          uxCurrentPlan.copyWith(planName: 'Progressive strengthening and mobility for the lumbar spine'),
          uxPreviousPlan,
        ],
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        programUxApp(programs, ProgramUxPlanRepository(programs), scale: 1.5, list: list, captureKey: key),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'program-enlarged-${list ? 'list' : 'detail'}');
      await tester.tap(find.byTooltip(list ? AppStrings.programActions : AppStrings.planActions));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'program-enlarged-menu-${list ? 'list' : 'detail'}');
    });
  }
}
