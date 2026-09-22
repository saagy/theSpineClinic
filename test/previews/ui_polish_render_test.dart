import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_form_fields.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/region_input_row.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:spine_clinic_app/shared/widgets/form_columns.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';
import '../fixtures/workspace_harness.dart';
import '../fixtures/workspace_data.dart';

import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [360.0, 1280.0]) {
    testWidgets('workspace and booking render at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: const WorkspaceHarness()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'patient-$width');
      await tester.ensureVisible(find.text(AppStrings.appointments).first);
      await tester.tap(find.text(AppStrings.appointments).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'appointments-$width');
      await tester.ensureVisible(find.text(AppStrings.tabDocuments).first);
      await tester.tap(find.text(AppStrings.tabDocuments).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'documents-$width');
      await tester.ensureVisible(find.text(AppStrings.notes).first);
      await tester.tap(find.text(AppStrings.notes).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'notes-$width');
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: AppTheme.light(clinicalBluePaletteLight),
            home: Scaffold(
              appBar: AppBar(title: const Text(AppStrings.newAppointment)),
              body: FormPageBody(
                onSave: () {},
                onCancel: () {},
                child: FormColumns(
                  first: BookingFormFields(
                    preselectedPatient: workspacePatient,
                    selectedType: AppointmentType.normalPtSession,
                    onTypeChanged: (_) {},
                    isRecurring: false,
                    onRecurringChanged: (_) {},
                    selectedDate: DateTime(2026, 9, 13),
                    onDateChanged: (_) {},
                    selectedTime: const TimeOfDay(hour: 9, minute: 0),
                    onTimeChanged: (_) {},
                    dateErrorText: null,
                    timeErrorText: null,
                  ),
                  second: FormSection(
                    title: AppStrings.targetRegion,
                    child: RegionInputRow(
                      modalityType: ModalityType.musclePain,
                      regionInput: const RegionInput(targetRegion: 'Deltoid'),
                      availableRegions: ModalityTargetRegion.regionsFor(ModalityType.musclePain),
                      onChanged: (_) {},
                      onDelete: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'form-controls-$width');
    });
  }
  for (final scale in [1.0, 1.5]) {
    testWidgets('target controls remain usable at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      RegionInput region = const RegionInput(targetRegion: 'Deltoid');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(clinicalBluePaletteLight),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, update) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: SingleChildScrollView(
                    child: RegionInputRow(
                      modalityType: ModalityType.musclePain,
                      regionInput: region,
                      availableRegions: ModalityTargetRegion.regionsFor(ModalityType.musclePain),
                      onChanged: (value) => update(() => region = value),
                      onDelete: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ChoiceChip), findsNothing);
      await tester.tap(find.byTooltip(AppStrings.increaseDuration));
      await tester.pump();
      expect(region.timeMinutes, 20);
      await tester.tap(find.byTooltip(AppStrings.decreaseDuration));
      await tester.pump();
      expect(region.timeMinutes, 15);
      expect(tester.takeException(), isNull);
    });
  }
}
