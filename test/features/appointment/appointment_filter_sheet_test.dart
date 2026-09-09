import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_sort_options.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

void main() {
  final testDoctor1 = Staff(
    id: 'doc-1',
    fullName: 'Dr. Sarah Ahmed',
    email: 'sarah@clinic.com',
    role: UserRole.doctor,
    isActive: true,
    createdAt: DateTime(2026),
  );

  final testDoctor2 = Staff(
    id: 'doc-2',
    fullName: 'Dr. Mohamed Tarek',
    email: 'mohamed@clinic.com',
    role: UserRole.doctor,
    isActive: true,
    createdAt: DateTime(2026),
  );

  Widget wrapSheet(Widget sheet, {Size size = const Size(800, 1000)}) {
    return ProviderScope(
      overrides: [
        allDoctorsForFilterProvider.overrideWith((ref) async => [testDoctor1, testDoctor2]),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(body: sheet),
        ),
      ),
    );
  }

  group('AppointmentFilterSheet Tests', () {
    testWidgets('renders date presets, clinic, status, type, and sort options', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapSheet(
          const AppointmentFilterSheet(
            initialDateFrom: null,
            initialDateTo: null,
            initialDoctorId: null,
            initialClinic: null,
            initialStatus: null,
            initialType: null,
            initialSort: AppointmentSortOption.dateDesc,
            canFilterDoctor: true,
            canFilterClinic: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.filtersButton), findsOneWidget);
      expect(find.text(AppStrings.resetFilters), findsOneWidget);

      // Date Range section
      expect(find.text(AppStrings.allDates), findsOneWidget);
      expect(find.text(AppStrings.thisMonth), findsOneWidget);
      expect(find.text(AppStrings.today), findsOneWidget);

      // Assigned Doctor section
      expect(find.text(AppStrings.assignedDoctors.toUpperCase()), findsOneWidget);
      expect(find.text(AppStrings.filterAllDoctors), findsOneWidget);

      // Clinic section
      expect(find.text(AppStrings.filterAllBranches), findsOneWidget);
      expect(find.text(ClinicLocation.tagamoa.displayLabel), findsOneWidget);
      expect(find.text(ClinicLocation.masrElgedida.displayLabel), findsOneWidget);

      // Status section
      expect(find.text(AppStrings.scheduled), findsOneWidget);
      expect(find.text(AppStrings.checkedIn), findsOneWidget);
      expect(find.text(AppStrings.cancelled), findsOneWidget);

      // Session Type section
      expect(find.text(AppStrings.normalPtSession), findsOneWidget);
      expect(find.text(AppStrings.spinalTractionSession), findsOneWidget);
      expect(find.text(AppStrings.initialAssessment), findsOneWidget);
      expect(find.text(AppStrings.reassessment), findsOneWidget);

      // Sort Order section
      expect(find.text(AppStrings.sortDateNewest), findsOneWidget);
      expect(find.text(AppStrings.sortDateOldest), findsOneWidget);

      // Apply button
      expect(find.text(AppStrings.applyFilters), findsOneWidget);
    });

    testWidgets('transitions to doctor picker sub-screen on doctor tile tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapSheet(
          const AppointmentFilterSheet(
            initialDateFrom: null,
            initialDateTo: null,
            initialDoctorId: null,
            initialClinic: null,
            initialStatus: null,
            initialType: null,
            initialSort: AppointmentSortOption.dateDesc,
            canFilterDoctor: true,
            canFilterClinic: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Doctor tile
      await tester.tap(find.text(AppStrings.filterAllDoctors));
      await tester.pumpAndSettle();

      // Should be on doctor picker view
      expect(find.text(AppStrings.searchDoctorsHint), findsOneWidget);
      expect(find.text(AppStrings.actionDone), findsOneWidget);
      expect(find.text('Dr. Sarah Ahmed'), findsOneWidget);
      expect(find.text('Dr. Mohamed Tarek'), findsOneWidget);

      // Select Dr. Sarah Ahmed
      await tester.tap(find.text('Dr. Sarah Ahmed'));
      await tester.pumpAndSettle();

      // Should return to main view with doctor selected
      expect(find.text('Dr. Sarah Ahmed'), findsOneWidget);
    });

    testWidgets('resets filters when Reset Filters is tapped', (WidgetTester tester) async {
      AppointmentFilterResult? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allDoctorsForFilterProvider.overrideWith((ref) async => [testDoctor1]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await AppointmentFilterSheet.show(
                      context: context,
                      dateFrom: DateTime(2026, 5, 1),
                      dateTo: DateTime(2026, 6, 1),
                      doctorId: 'doc-1',
                      clinic: ClinicLocation.tagamoa,
                      status: AppointmentStatus.scheduled,
                      type: AppointmentType.normalPtSession,
                      sort: AppointmentSortOption.dateAsc,
                      canFilterDoctor: true,
                      canFilterClinic: true,
                    );
                  },
                  child: const Text('Open Filters'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Sarah Ahmed'), findsOneWidget);

      // Tap Reset Filters
      await tester.tap(find.text(AppStrings.resetFilters));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.filterAllDoctors), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text(AppStrings.applyFilters));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.dateFrom, isNull);
      expect(result!.dateTo, isNull);
      expect(result!.doctorId, isNull);
      expect(result!.clinic, isNull);
      expect(result!.status, isNull);
      expect(result!.type, isNull);
      expect(result!.sortOption, AppointmentSortOption.dateDesc);
    });

    testWidgets('selects status, type, and sort and applies them', (WidgetTester tester) async {
      AppointmentFilterResult? result;

      await tester.pumpWidget(
        wrapSheet(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AppointmentFilterSheet.show(
                  context: context,
                  dateFrom: null,
                  dateTo: null,
                  doctorId: null,
                  clinic: null,
                  status: null,
                  type: null,
                  sort: AppointmentSortOption.dateDesc,
                  canFilterDoctor: false,
                  canFilterClinic: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Select Tagamoa clinic
      await tester.tap(find.text(ClinicLocation.tagamoa.displayLabel));
      await tester.pumpAndSettle();

      // Select Scheduled status
      await tester.tap(find.text(AppStrings.scheduled));
      await tester.pumpAndSettle();

      // Select PT Session type
      await tester.ensureVisible(find.text(AppStrings.normalPtSession));
      await tester.tap(find.text(AppStrings.normalPtSession));
      await tester.pumpAndSettle();

      // Select Date (Oldest) sort
      await tester.scrollUntilVisible(find.text(AppStrings.sortDateOldest), 100);
      await tester.tap(find.text(AppStrings.sortDateOldest));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text(AppStrings.applyFilters));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.clinic, ClinicLocation.tagamoa);
      expect(result!.status, AppointmentStatus.scheduled);
      expect(result!.type, AppointmentType.normalPtSession);
      expect(result!.sortOption, AppointmentSortOption.dateAsc);
    });
  });
}
