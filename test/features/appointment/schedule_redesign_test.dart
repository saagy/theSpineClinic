import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_table_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_search_field.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_toolbar.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

void main() {
  group('AppointmentSearchField Tests', () {
    testWidgets('renders hint text and triggers debounced search', (
      WidgetTester tester,
    ) async {
      String query = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentSearchField(
              onChanged: (val) => query = val,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.searchByPatientNameHint), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'John');
      await tester.pump(const Duration(milliseconds: 100));
      expect(query, ''); // Not yet fired (within 300ms)

      await tester.pump(const Duration(milliseconds: 250));
      expect(query, 'John'); // Fired after 300ms

      // Clear button tap
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(query, '');
    });
  });

  group('ScheduleToolbar Tests', () {
    testWidgets('renders search field and filter button without badge when 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleToolbar(
              searchQuery: '',
              onSearchChanged: (_) {},
              activeFiltersCount: 0,
              onFilterTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.filtersButton), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders circular badge when activeFiltersCount > 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleToolbar(
              searchQuery: '',
              onSearchChanged: (_) {},
              activeFiltersCount: 1,
              onFilterTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.filtersButton), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('AppointmentAgendaTableHeader Tests', () {
    testWidgets('omits Doctor column when showDoctor is false', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppointmentAgendaTableHeader(showDoctor: false),
          ),
        ),
      );

      expect(find.text(AppStrings.appointmentColTime.toUpperCase()), findsOneWidget);
      expect(find.text(AppStrings.appointmentColPatient.toUpperCase()), findsOneWidget);
      expect(find.text(AppStrings.appointmentColType.toUpperCase()), findsOneWidget);
      expect(find.text(AppStrings.appointmentColDoctor.toUpperCase()), findsNothing);
      expect(find.text(AppStrings.appointmentColStatus.toUpperCase()), findsOneWidget);
    });

    testWidgets('includes Doctor column when showDoctor is true', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppointmentAgendaTableHeader(showDoctor: true),
          ),
        ),
      );

      expect(find.text(AppStrings.appointmentColDoctor.toUpperCase()), findsOneWidget);
    });
  });

  group('ScheduleFilterSheet Tests', () {
    final testDoctor = Staff(
      id: 'doc-1',
      fullName: 'Dr. Khaled Aly',
      email: 'khaled@clinic.com',
      role: UserRole.doctor,
      isActive: true,
      createdAt: DateTime(2026),
    );

    testWidgets('applies selected doctor and resets', (
      WidgetTester tester,
    ) async {
      ScheduleFilterResult? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDoctorsForFilterProvider.overrideWith(
              (ref) async => [testDoctor],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await ScheduleFilterSheet.show(
                      context: context,
                      doctorId: 'doc-1',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.filtersButton), findsOneWidget);
      expect(find.text('Dr. Khaled Aly'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.text(AppStrings.resetFilters).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.filterAllDoctors), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text(AppStrings.applyFilters));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.doctorId, isNull);
    });
  });
}
