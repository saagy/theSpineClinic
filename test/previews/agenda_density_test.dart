import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurring_pattern_picker.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';
import '../fixtures/workspace_data.dart';
import '../fixtures/workspace_overrides.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [320.0, 360.0, 430.0, 650.0, 1280.0]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets('dense agenda and weekdays fit $width at scale $scale', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final sessions = TextEditingController();
        addTearDown(sessions.dispose);
        final key = GlobalKey();
        Set<int> selected = {DateTime.saturday};
        final rows = <Widget>[
          for (final entry in [
            ('Dina Sherif', AppointmentStatus.scheduled),
            ('Ziad Abaza', AppointmentStatus.checkedIn),
            ('Nour Ahmed Mohamed Abdelrahman Hassan', AppointmentStatus.cancelled),
          ].indexed)
            AppointmentAgendaRow(
              showDoctor: false,
              item: AppointmentWithPatient(
                patient: workspacePatient.copyWith(fullName: entry.$2.$1),
                appointment: Appointment(
                  id: 'appt-${entry.$1}',
                  patientId: workspacePatient.id,
                  type: AppointmentType.reassessment,
                  status: entry.$2.$2,
                  scheduledAt: DateTime(2026, 9, 13, 9, entry.$1),
                  createdAt: DateTime(2026),
                ),
              ),
            ),
        ];
        final picker = StatefulBuilder(
          builder: (context, update) => RecurringPatternPicker(
            selectedWeekdays: selected,
            onWeekdaysChanged: (days) => update(() => selected = days),
            sessionsController: sessions,
          ),
        );
        rows.add(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 420,
                child: FormSection(title: AppStrings.recurrencePattern, child: picker),
              ),
            ),
          ),
        );
        final app = MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(clinicalBluePaletteLight),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(child: Column(children: rows)),
            ),
          ),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ProviderScope(
              overrides: [currentUserProvider.overrideWith(() => WorkspaceUser('reception'))],
              child: app,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.checkIn), findsNothing);
        expect(find.text(AppStrings.undo), findsNothing);
        if (scale == 1 && width < 650) {
          expect(
            tester.getSize(find.byType(AppointmentAgendaRow).first).height,
            lessThanOrEqualTo(64),
          );
        }
        for (final label in AppStrings.weekdayShortLabels) {
          final button = find.widgetWithText(OutlinedButton, label);
          expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
          expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
          expect(tester.getRect(button).right, lessThanOrEqualTo(width));
        }
        await tester.ensureVisible(find.text('Fri'));
        await tester.tap(find.text('Fri'));
        await tester.pump();
        expect(selected, containsAll([DateTime.saturday, DateTime.friday]));
        await tester.tap(find.text('Fri'));
        await tester.pump();
        expect(selected, isNot(contains(DateTime.friday)));
        if (scale == 1 && (width == 360 || width == 1280)) {
          await capturePolish(tester, key, 'dense-agenda-$width');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
