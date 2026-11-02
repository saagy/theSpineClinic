import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_filter_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_filter_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_sort_options.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_filter_sheet.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_tile.dart';
import '../fixtures/staff_workspace.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [390.0, 1440.0]) {
    for (final name in ['staff', 'patients', 'schedule']) {
      testWidgets('$name filter at $width', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: key, child: ProviderScope(
          overrides: [allDoctorsForFilterProvider.overrideWith((ref) async => [staffRoster.last])],
          child: MaterialApp(debugShowCheckedModeBanner: false,
            theme: AppTheme.light(clinicalBluePaletteLight),
            home: Scaffold(body: Builder(builder: (context) => TextButton(
              child: const Text('Open'),
              onPressed: () => switch(name) {
                'staff' => StaffFilterSheet.show(context: context,
                  initialFilters: const StaffListFilters(), initialSort: StaffSortOption.nameAsc),
                'patients' => PatientFilterSheet.show(context: context, clinic: null,
                  doctorId: staffRoster.last.id, sort: PatientSortOption.nameAsc, canFilterDoctor: true),
                _ => ScheduleFilterSheet.show(context: context, doctorId: staffRoster.last.id),
              },
            ))),
          ),
        )));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'filter-$name-$width');
        if (name != 'staff') {
          await tester.tap(find.text(staffRoster.last.fullName));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'Youssef');
          await tester.pumpAndSettle();
          expect(find.text(staffRoster.last.fullName), findsOneWidget);
          await tester.tap(find.text(staffRoster.last.fullName));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(AppStrings.applyFilters));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('large text and initials edge cases remain readable', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(
      theme: AppTheme.light(clinicalBluePaletteLight),
      home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(body: ListView(children: [
          for (final name in ['123', 'A', '', '123 Ahmed Hassan', staffRoster.last.fullName])
            StaffAccountTile(staff: staffRoster.last.copyWith(fullName: name), onTap: () {}),
        ])),
      ),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capturePolish(tester, key, 'staff-large-text');
  });
}
