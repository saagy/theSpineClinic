import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_balance_pill.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_data_table.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_filter_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_mobile_list.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_sort_options.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_table_pagination.dart';

Widget _wrap(Widget child, {Size size = const Size(1200, 800)}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(clinicalBluePaletteLight),
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  final samplePatient = Patient(
    id: 'p-1',
    fullName: 'Maria Clara Santos',
    phoneNumber: '+63 917 123 4567',
    clinic: ClinicLocation.tagamoa,
    sessionBalance: 8,
    tractionBalance: 2,
    createdAt: DateTime(2026, 1, 15),
    nextVisitDate: DateTime(2026, 9, 10, 14, 0),
  );

  group('PatientMonogramBadge Tests', () {
    testWidgets('extracts initials from multi-word name', (tester) async {
      await tester.pumpWidget(_wrap(const PatientMonogramBadge(name: 'Maria Santos')));
      expect(find.text('MS'), findsOneWidget);
    });

    testWidgets('extracts single initial from single-word name', (tester) async {
      await tester.pumpWidget(_wrap(const PatientMonogramBadge(name: 'John')));
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('falls back to user icon for empty or non-letter name', (tester) async {
      await tester.pumpWidget(_wrap(const PatientMonogramBadge(name: '   ')));
      expect(find.byIcon(LucideIcons.user), findsOneWidget);
    });
  });

  group('PatientBalancePill Tests', () {
    testWidgets('displays formatted balances with tabular figures', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PatientBalancePill(
            sessionBalance: 5,
            tractionBalance: 3,
          ),
        ),
      );
      expect(find.text('5S  •  3T'), findsOneWidget);
    });

    testWidgets('displays zero balance without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PatientBalancePill(
            sessionBalance: 0,
            tractionBalance: 0,
          ),
        ),
      );
      expect(find.text('0S  •  0T'), findsOneWidget);
    });
  });

  group('PatientTablePagination Tests', () {
    testWidgets('displays showing record bounds and disables previous on page 1', (tester) async {
      bool prevTapped = false;
      bool nextTapped = false;

      await tester.pumpWidget(
        _wrap(
          PatientTablePagination(
            currentPage: 1,
            totalPages: 5,
            totalCount: 142,
            pageSize: 30,
            hasPrevious: false,
            hasNext: true,
            onPrevious: () => prevTapped = true,
            onNext: () => nextTapped = true,
          ),
        ),
      );

      expect(find.text('Showing 1 to 30 of 142 patients'), findsOneWidget);
      expect(find.text('Page 1 of 5'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(nextTapped, isTrue);

      await tester.tap(find.text('Previous'));
      await tester.pump();
      expect(prevTapped, isFalse);
    });
  });

  group('PatientDataTable Desktop Tests', () {
    testWidgets('renders patient row columns and handles tap', (tester) async {
      Patient? tappedPatient;

      await tester.pumpWidget(
        _wrap(
          PatientDataTable(
            patients: [samplePatient],
            onPatientTap: (p) => tappedPatient = p,
          ),
          size: const Size(1200, 800),
        ),
      );

      expect(find.text('Maria Clara Santos'), findsOneWidget);
      expect(find.text('+63 917 123 4567'), findsOneWidget);
      expect(find.text('Tagamoa'), findsOneWidget);

      await tester.tap(find.text('Maria Clara Santos'));
      await tester.pump();
      expect(tappedPatient?.id, equals('p-1'));
    });
  });

  group('PatientMobileList Tests', () {
    testWidgets('renders mobile patient row and handles tap', (tester) async {
      Patient? tappedPatient;

      await tester.pumpWidget(
        _wrap(
          PatientMobileList(
            patients: [samplePatient],
            hasMore: false,
            onRefresh: () async {},
            onPatientTap: (p) => tappedPatient = p,
            scrollController: ScrollController(),
          ),
          size: const Size(400, 800),
        ),
      );

      expect(find.text('Maria Clara Santos'), findsOneWidget);
      expect(find.text('+63 917 123 4567'), findsOneWidget);
      expect(find.text('Tagamoa'), findsOneWidget);

      await tester.tap(find.text('Maria Clara Santos'));
      await tester.pump();
      expect(tappedPatient?.id, equals('p-1'));
    });
  });

  group('PatientFilterSheet Tests', () {
    testWidgets('renders branch and sort options', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PatientFilterSheet(
            initialClinic: null,
            initialDoctorId: null,
            initialSort: PatientSortOption.nameAsc,
            canFilterDoctor: false,
          ),
          size: const Size(600, 800),
        ),
      );

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('All Branches'), findsOneWidget);
      expect(find.text('Tagamoa'), findsOneWidget);
      expect(find.text('Masr El-Gedida'), findsOneWidget);
      expect(find.text('Name (A → Z)'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('opens doctor picker sub-screen on doctor tile tap', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PatientFilterSheet(
            initialClinic: null,
            initialDoctorId: null,
            initialSort: PatientSortOption.nameAsc,
            canFilterDoctor: true,
          ),
          size: const Size(600, 800),
        ),
      );

      expect(find.text('ASSIGNED DOCTORS'), findsOneWidget);
      expect(find.text('All Doctors'), findsOneWidget);

      await tester.tap(find.text('All Doctors'));
      await tester.pumpAndSettle();

      expect(find.text('Assigned Doctors'), findsOneWidget);
      expect(find.text('Search doctors…'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });
}
