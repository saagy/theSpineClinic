import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/target_region_picker.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/target_region_picker_options.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import '../../previews/ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final bool compact in [false, true]) {
    testWidgets(
      'mobile step preserves form and reaches last region (compact=$compact)',
      (tester) async {
        tester.view.physicalSize = Size(compact ? 320 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final GlobalKey captureKey = GlobalKey();
        final TextEditingController notes = TextEditingController();
        addTearDown(notes.dispose);
        String value = 'Deltoid';
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
              theme: compact
                  ? AppTheme.dark(clinicalBluePaletteDark)
                  : AppTheme.light(clinicalBluePaletteLight),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(compact ? 1.5 : 1)),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => AppBottomSheet.show<void>(
                      context: context,
                      title: AppStrings.editTreatmentPlan,
                      builder: (context, controller) => StatefulBuilder(
                        builder: (context, update) => ListView(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          children: [
                            TextField(controller: notes),
                            TargetRegionPicker(
                              label: AppStrings.targetRegion,
                              value: value,
                              regions: ModalityRegionCatalog.releaseRegions,
                              onChanged: (selection) =>
                                  update(() => value = selection),
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
        await tester.enterText(find.byType(TextField), 'Preserve this note');
        await tester.tap(find.text('Deltoid'));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsOneWidget);
        expect(tester.testTextInput.isVisible, isFalse);
        expect(find.text(AppStrings.editTreatmentPlan), findsNothing);
        final Finder list = find.descendant(
          of: find.byType(TargetRegionPickerOptions),
          matching: find.byType(ListView),
        );
        final double listBottom = tester.getBottomLeft(list).dy;
        expect(listBottom, closeTo(tester.view.physicalSize.height, 1));
        await capturePolish(
          tester,
          captureKey,
          compact ? 'region-mobile-dark-large-text' : 'region-mobile',
        );

        await tester.tap(find.byTooltip(AppStrings.backTooltip));
        await tester.pumpAndSettle();
        expect(value, 'Deltoid');
        expect(notes.text, 'Preserve this note');
        expect(find.text(AppStrings.editTreatmentPlan), findsOneWidget);

        await tester.tap(find.text('Deltoid'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Paraspinal'),
          300,
          scrollable: find.descendant(
            of: list,
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(find.text('Paraspinal'));
        await tester.pumpAndSettle();
        expect(value, 'Paraspinal');
        expect(notes.text, 'Preserve this note');
        expect(find.byType(TargetRegionPickerOptions), findsNothing);

        await tester.tap(find.text('Paraspinal'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'no match');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.noTargetRegionsFound), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capturePolish(
          tester,
          captureKey,
          compact
              ? 'region-mobile-keyboard-large-text'
              : 'region-mobile-keyboard',
        );
        tester.view.resetViewInsets();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsOneWidget);
        expect(find.text(AppStrings.editTreatmentPlan), findsOneWidget);
        expect(value, 'Paraspinal');
        expect(notes.text, 'Preserve this note');
        await tester.tap(find.byTooltip(AppStrings.close));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
