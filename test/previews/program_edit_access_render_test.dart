import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_documents.dart';
import '../fixtures/program_ux_harness.dart';
import '../fixtures/workspace_data.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final (width, scale) in [(320.0, 1.0), (390.0, 1.0), (768.0, 1.0), (1280.0, 1.0), (360.0, 1.5)]) {
    for (final dark in [false, true]) {
      testWidgets('program edit access at $width scale=$scale dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final programs = ProgramUxRepository();
        programs.program = programs.program!.copyWith(
          examination: 'Reduced lumbar flexion with pain at end range. Normal lower-limb strength and sensation.',
          imagingNotes: 'Lumbar MRI report reviewed with the patient.',
          exaggeratingPositions: 'Prolonged sitting and loaded flexion.',
          relievingPositions: 'Walking and supported rest.',
          notes: 'Review progress and exercise tolerance at the next visit.',
        );
        final key = GlobalKey();
        await tester.pumpWidget(
          programUxApp(
            programs,
            ProgramUxPlanRepository(programs),
            dark: dark,
            scale: scale,
            captureKey: key,
            documents: [workspaceDocuments.first],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final suffix = '$width-$scale-${dark ? 'dark' : 'light'}';
        await capturePolish(tester, key, 'program-overview-$suffix');
        final manage = find.descendant(of: find.byType(ProgramDetailDocuments), matching: find.text(AppStrings.manage));
        await tester.ensureVisible(manage);
        await tester.pumpAndSettle();
        expect(find.byTooltip(AppStrings.editProgramDetails).hitTestable(), findsOneWidget);
        await capturePolish(tester, key, 'program-documents-$suffix');
        await tester.tap(manage);
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.attachImagingFiles).hitTestable(), findsOneWidget);
        expect(find.text(AppStrings.saveChanges).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'program-document-editor-$suffix');
        await tester.tap(find.text(AppStrings.cancel));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(AppStrings.programActions));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'program-record-menu-$suffix');
      });
    }
  }
}
