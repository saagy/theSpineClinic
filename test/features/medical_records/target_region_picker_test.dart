import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/target_region_picker.dart';
import '../../previews/ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  testWidgets(
    'filters target regions and returns the selected option on desktop',
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
              body: StatefulBuilder(
                builder: (context, setState) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: TargetRegionPicker(
                    label: AppStrings.targetRegion,
                    value: value,
                    regions:
                        ModalityRegionCatalog.musclePainAndMassBuiltRegions,
                    onChanged: (selection) => setState(() => value = selection),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Deltoid'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.targetRegionOptions(9)), findsOneWidget);
      await capturePolish(tester, key, 'target-region-picker-desktop');

      await tester.enterText(find.byType(TextField), 'Calf');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calf').last);
      await tester.pumpAndSettle();

      expect(value, 'Calf');
      expect(find.text('Calf'), findsOneWidget);
    },
  );
}
