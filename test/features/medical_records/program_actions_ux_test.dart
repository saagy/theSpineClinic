import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_program_row.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import '../../fixtures/program_ux_harness.dart';

void main() {
  testWidgets('program status changes only program status', (tester) async {
    final programs = ProgramUxRepository();
    final plans = ProgramUxPlanRepository(programs);
    await tester.pumpWidget(programUxApp(programs, plans));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.changeProgramStatus));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<ProgramStatus>), findsNWidgets(3));
    final current = tester.widget<PopupMenuItem<ProgramStatus>>(
      find.widgetWithText(PopupMenuItem<ProgramStatus>, AppStrings.programStatusLabel('Active')),
    );
    expect(current.enabled, isFalse);
    await tester.tap(find.widgetWithText(PopupMenuItem<ProgramStatus>, AppStrings.completeProgram));
    await tester.pumpAndSettle();
    expect(programs.program!.status, ProgramStatus.completed);
    expect(programs.program!.activePlan!.id, uxCurrentPlan.id);
    expect(find.text(AppStrings.programStatusLabel('Completed')), findsOneWidget);
  });

  testWidgets('new plan copies treatments and preserves the original; editing keeps the id', (tester) async {
    final programs = ProgramUxRepository();
    final plans = ProgramUxPlanRepository(programs);
    await tester.pumpWidget(programUxApp(programs, plans));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.planActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.createTreatmentPlan));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.copiedPlanHint), findsOneWidget);
    expect(find.text(AppStrings.newPlanName(uxCurrentPlan.planName)), findsOneWidget);
    expect(find.text(AppStrings.replacePlanHint(uxCurrentPlan.planName)), findsOneWidget);
    await tester.tap(find.text(AppStrings.saveAndUsePlan));
    await tester.pumpAndSettle();
    expect(plans.savedId, isNull);
    expect(plans.savedModalities!.single.regions.single.timeMinutes, 15);
    expect(programs.program!.treatmentPlans.length, 3);
    expect(programs.program!.treatmentPlans.firstWhere((p) => p.id == uxCurrentPlan.id).isActive, isFalse);
    expect(programs.program!.activePlan!.id, 'new-plan');
    await tester.tap(find.byTooltip(AppStrings.planActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.editThisPlan));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.editPlanHint), findsOneWidget);
    await tester.tap(find.text(AppStrings.saveAndUsePlan));
    await tester.pumpAndSettle();
    expect(plans.savedId, 'new-plan');
    expect(programs.program!.treatmentPlans.length, 3);
  });

  testWidgets('switch requires confirmation and preserves program status; cancel is safe', (tester) async {
    final programs = ProgramUxRepository();
    final plans = ProgramUxPlanRepository(programs);
    await tester.pumpWidget(programUxApp(programs, plans));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${AppStrings.previousPlans} (1)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(AppStrings.useThisPlan));
    await tester.tap(find.text(AppStrings.useThisPlan));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.usePlanConfirmation(uxPreviousPlan.planName, uxCurrentPlan.planName)), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(plans.activatedId, isNull);
    await tester.tap(find.text(AppStrings.useThisPlan));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, AppStrings.useThisPlan);
    final label = tester.element(find.descendant(of: button, matching: find.byType(Text)));
    Focus.of(label).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationDialog), findsNothing);
    expect(plans.activatedId, uxPreviousPlan.id);
    expect(programs.program!.status, ProgramStatus.active);
    expect(programs.program!.activePlan!.id, uxPreviousPlan.id);
  });

  testWidgets('Programs tab menu changes status and refreshes the row using the keyboard', (tester) async {
    final programs = ProgramUxRepository();
    await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs), list: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.programActions));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.editProgramDetails), findsOneWidget);
    expect(find.text(AppStrings.deleteProgram), findsOneWidget);
    expect(find.text(AppStrings.viewDetails), findsNothing);
    Focus.of(tester.element(find.text(AppStrings.changeStatus))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(programs.statusWrites, 0);
    expect(find.byType(PopupMenuItem<ProgramStatus>), findsNWidgets(3));
    Focus.of(tester.element(find.text(AppStrings.completeProgram))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(programs.statusWrites, 1);
    expect(programs.program!.status, ProgramStatus.completed);
    expect(programs.program!.activePlan!.id, uxCurrentPlan.id);
    expect(find.text(AppStrings.programStatusUpdated(AppStrings.programCompleted)), findsOneWidget);
    expect(find.text(AppStrings.noActivePrograms), findsOneWidget);
    await tester.tap(find.text(AppStrings.archivedProgramsCount(1)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.programCompleted), findsOneWidget);
    expect(find.text(AppStrings.currentTreatmentPlan), findsNothing);
  });

  testWidgets('tapping a Programs tab row opens details without changing data', (tester) async {
    final programs = ProgramUxRepository();
    await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs), list: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(WorkspaceProgramRow));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.currentTreatmentPlan), findsOneWidget);
    expect(programs.statusWrites, 0);
  });

  for (final role in ['doctor', 'reception']) {
    testWidgets('$role gets a navigation chevron and no program mutation controls', (tester) async {
      final programs = ProgramUxRepository();
      await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs), list: true, role: role));
      await tester.pumpAndSettle();
      expect(find.byTooltip(AppStrings.programActions), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text(AppStrings.editProgramDetails), findsNothing);
      expect(find.text(AppStrings.deleteProgram), findsNothing);
      await tester.tap(find.byTooltip(AppStrings.viewDetails));
      await tester.pumpAndSettle();
      expect(find.byTooltip(AppStrings.changeProgramStatus), findsNothing);
      expect(find.byTooltip(AppStrings.planActions), findsNothing);
      expect(programs.statusWrites, 0);
    });
  }

  testWidgets('saving an unselected copy keeps the current plan', (tester) async {
    final programs = ProgramUxRepository();
    final plans = ProgramUxPlanRepository(programs);
    await tester.pumpWidget(programUxApp(programs, plans));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.planActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.createTreatmentPlan));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.savedPlanOnlyHint), findsOneWidget);
    await tester.tap(find.text(AppStrings.savePlan));
    await tester.pumpAndSettle();
    expect(programs.program!.activePlan!.id, uxCurrentPlan.id);
    expect(programs.program!.treatmentPlans.length, 3);
  });

  testWidgets('deleting from Programs tab refreshes the list', (tester) async {
    final programs = ProgramUxRepository();
    await tester.pumpWidget(programUxApp(programs, ProgramUxPlanRepository(programs), list: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.programActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteProgram));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();
    expect(programs.program, isNull);
    expect(find.byTooltip(AppStrings.programActions), findsNothing);
    expect(find.text(AppStrings.noActivePrograms), findsOneWidget);
  });
}
