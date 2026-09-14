import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/target_region_picker.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/target_region_picker_options.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import '../../previews/ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  testWidgets(
    'uses the same selection step and preserves the form on desktop',
    (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String value = 'Deltoid';
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => AppBottomSheet.show<void>(
                    context: context,
                    title: AppStrings.editTreatmentPlan,
                    builder: (context, controller) => StatefulBuilder(
                      builder: (context, setState) => ListView(
                        controller: controller,
                        children: [
                          const Text('Form content'),
                          TargetRegionPicker(
                            label: AppStrings.targetRegion,
                            value: value,
                            regions: ModalityRegionCatalog
                                .musclePainAndMassBuiltRegions,
                            onChanged: (selection) =>
                                setState(() => value = selection),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deltoid'));
      await tester.pumpAndSettle();
      expect(find.byType(TargetRegionPickerOptions), findsOneWidget);
      expect(find.text(AppStrings.editTreatmentPlan), findsNothing);
      await capturePolish(tester, key, 'target-region-picker-desktop');

      await tester.enterText(find.byType(TextField), 'Calf');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calf').last);
      await tester.pumpAndSettle();

      expect(value, 'Calf');
      expect(find.text('Calf'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(TargetRegionPicker),
          matching: find.text('Calf'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.backTooltip));
      await tester.pumpAndSettle();
      expect(value, 'Calf');
      expect(find.text(AppStrings.editTreatmentPlan), findsOneWidget);
    },
  );
}
