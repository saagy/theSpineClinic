import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_edit_section.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_form_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_detail_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_conditions.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_findings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_documents.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_clinical_inputs.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import '../../fixtures/program_ux_harness.dart';

void main() {
  for (final width in [360.0, 1280.0]) {
    testWidgets('fixed Edit opens from a scrolled record using the keyboard at $width', (tester) async {
      tester.view.physicalSize = Size(width, 750);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final programs = ProgramUxRepository();
      await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppStrings.addDocument));
      await tester.pumpAndSettle();
      final action = find.byTooltip(AppStrings.editProgramDetails);
      final label = find.descendant(of: action, matching: find.byType(Text));
      Focus.of(tester.element(label)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(ProgramFormScreen), findsOneWidget);
      expect(
        tester.widget<ProgramFormScreen>(find.byType(ProgramFormScreen)).initialSection,
        ProgramEditSection.conditions,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 1280.0]) {
    for (final section in ProgramEditSection.values) {
      testWidgets('$section shortcut opens its fields and Cancel preserves position at $width', (tester) async {
        tester.view.physicalSize = Size(width, 750);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final programs = ProgramUxRepository();
        programs.program = programs.program!.copyWith(
          examination: List.filled(12, 'Pain during loaded lumbar flexion.').join('\n'),
          notes: 'Continue to monitor movement quality.',
        );
        await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs)));
        await tester.pumpAndSettle();
        final target = switch (section) {
          ProgramEditSection.conditions => find.byType(ProgramDetailConditions),
          ProgramEditSection.findings => find.byType(ProgramDetailFindings),
          ProgramEditSection.documents => find.byType(ProgramDetailDocuments),
        };
        final action = find.descendant(of: target, matching: find.byType(TextButton));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        final detailScroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
        final offset = detailScroll.pixels;
        expect(find.byTooltip(AppStrings.editProgramDetails).hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(tester.widget<ProgramFormScreen>(find.byType(ProgramFormScreen)).initialSection, section);
        final targetLabel = switch (section) {
          ProgramEditSection.conditions => AppStrings.programConditions,
          ProgramEditSection.findings => AppStrings.clinicalFindingsSection,
          ProgramEditSection.documents => AppStrings.tabDocuments,
        };
        final labelRect = tester.getRect(find.text(targetLabel));
        expect(labelRect.overlaps(tester.getRect(find.byType(FormPageBody))), isTrue);
        expect(find.text(AppStrings.saveChanges).hitTestable(), findsOneWidget);
        expect(tester.testTextInput.isVisible, isFalse);
        await tester.tap(find.text(AppStrings.cancel));
        await tester.pumpAndSettle();
        expect(find.byType(ProgramFormScreen), findsNothing);
        expect(detailScroll.pixels, closeTo(offset, 1));
        expect(programs.edits, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('findings draft survives failure; retry updates the record and restores position', (tester) async {
    tester.view.physicalSize = const Size(360, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final programs = ProgramUxRepository()..failSave = true;
    programs.program = programs.program!.copyWith(examination: 'Initial examination');
    await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs)));
    await tester.pumpAndSettle();
    final action = find.descendant(of: find.byType(ProgramDetailFindings), matching: find.byType(TextButton));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    final detailScroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final offset = detailScroll.pixels;
    await tester.tap(action);
    await tester.pumpAndSettle();
    final examination = find
        .descendant(of: find.byType(ProgramClinicalInputs), matching: find.byType(TextFormField))
        .first;
    await tester.enterText(examination, 'Updated examination');
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramFormScreen), findsOneWidget);
    expect(find.text('Updated examination'), findsOneWidget);
    expect(programs.program!.examination, 'Initial examination');
    programs.failSave = false;
    await tester.tap(find.text(AppStrings.retrySave));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramFormScreen), findsNothing);
    expect(programs.program!.examination, 'Updated examination');
    expect(programs.edits, 2);
    expect(detailScroll.pixels, closeTo(offset, 1));
    expect(find.text('Updated examination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('program overflow offers editing before export and separated deletion', (tester) async {
    final programs = ProgramUxRepository();
    await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.programActions));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuDivider), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(AppStrings.editProgramDetails)).dy,
      lessThan(tester.getTopLeft(find.text(AppStrings.exportPdf)).dy),
    );
    expect(
      tester.getTopLeft(find.text(AppStrings.exportPdf)).dy,
      lessThan(tester.getTopLeft(find.text(AppStrings.deleteProgram)).dy),
    );
    await tester.tap(find.text(AppStrings.editProgramDetails));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramFormScreen), findsOneWidget);
    expect(
      tester.widget<ProgramFormScreen>(find.byType(ProgramFormScreen)).initialSection,
      ProgramEditSection.conditions,
    );
  });

  for (final role in ['doctor', 'reception']) {
    testWidgets('$role has export access without editing or deletion', (tester) async {
      final programs = ProgramUxRepository();
      await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs), role: role));
      await tester.pumpAndSettle();
      expect(find.byTooltip(AppStrings.editProgramDetails), findsNothing);
      expect(find.text(AppStrings.edit), findsNothing);
      expect(find.text(AppStrings.addDocument), findsNothing);
      await tester.tap(find.byTooltip(AppStrings.programActions));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.exportPdf), findsOneWidget);
      expect(find.text(AppStrings.editProgramDetails), findsNothing);
      expect(find.text(AppStrings.deleteProgram), findsNothing);
      expect(programs.edits, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a read-only form submission is rejected with visible feedback', (tester) async {
    final programs = ProgramUxRepository();
    await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs), role: 'doctor'));
    await tester.pumpAndSettle();
    final program = programs.program!;
    GoRouter.of(
      tester.element(find.byType(ProgramDetailScreen)),
    ).go('/patient/${program.patientId}/programs/${program.id}/edit');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();
    expect(programs.edits, 0);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(AppStrings.fromKey('error_permission_denied')), findsOneWidget);
  });
}
