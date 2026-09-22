import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_controls.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_lists.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);

  for (final width in [320.0, 360.0, 1280.0]) {
    for (final scale in [1.0, 1.6]) {
      for (final dark in [false, true]) {
        testWidgets(
          'booking workboard fits $width at text scale $scale, dark=$dark',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final key = GlobalKey();
            final date = DateTime(2026, 9, 22);
            final state = BookingWorkboardState(
              date: date,
              duePatients: [
                _patient('1', 'Khaled Bichara', DateTime(2026, 9, 4)),
                _patient(
                  '2',
                  'Nour Ahmed Mohamed Abdelrahman Hassan',
                  DateTime(2026, 9, 5),
                ),
                _patient('3', 'Saba Mubarak', DateTime(2026, 9, 24)),
              ],
            );

            await tester.pumpWidget(
              RepaintBoundary(
                key: key,
                child: ProviderScope(
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light(clinicalBluePaletteLight),
                    darkTheme: AppTheme.dark(clinicalBluePaletteDark),
                    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                    home: MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Scaffold(
                        body: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1080),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  BookingWorkboardControls(
                                    date: date,
                                    doctor: null,
                                    onChooseDate: () {},
                                    onFilterDoctor: () {},
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: BookingWorkboardLists(
                                      state: state,
                                      wide: width >= 900,
                                      onRefresh: () async {},
                                      onViewChanged: (_) {},
                                      onCall: (_) {},
                                      onBook: (_) {},
                                      onRemind: (_) {},
                                      onStop: (_) {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
            await capturePolish(tester, key, 'booking-$width-$scale-$dark');
          },
        );
      }
    }
  }
}

Patient _patient(String id, String name, DateTime due) => Patient(
  id: id,
  fullName: name,
  phoneNumber: '+201020006233',
  clinic: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
  nextVisitDate: due,
);
