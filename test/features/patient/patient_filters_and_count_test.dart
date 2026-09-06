import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_filters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_list_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_table_pagination.dart';

class _MockPatientRepository implements PatientRepository {
  PatientFilters? lastGetAllFilters;
  PatientFilters? lastCountFilters;
  Completer<Result<List<Patient>>>? getAllCompleter;
  Completer<Result<int>>? countCompleter;
  Result<List<Patient>> getAllResult = const Result.success([]);
  Result<int> countResult = const Result.success(0);

  @override
  Future<Result<List<Patient>>> getAllPatients({
    PatientFilters filters = const PatientFilters(),
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
    int offset = 0,
    int limit = 30,
    String orderBy = 'full_name',
    bool ascending = true,
  }) async {
    lastGetAllFilters = filters.isNotEmpty
        ? filters
        : PatientFilters(clinic: clinic, doctorId: doctorId, search: query);
    if (getAllCompleter != null) return getAllCompleter!.future;
    return getAllResult;
  }

  @override
  Future<Result<int>> countAllPatients({
    PatientFilters filters = const PatientFilters(),
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
  }) async {
    lastCountFilters = filters.isNotEmpty
        ? filters
        : PatientFilters(clinic: clinic, doctorId: doctorId, search: query);
    if (countCompleter != null) return countCompleter!.future;
    return countResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Patient _createPatient(String id, String name) {
  return Patient(
    id: id,
    fullName: name,
    phoneNumber: '+20100000000',
    clinic: ClinicLocation.tagamoa,
    sessionBalance: 5,
    tractionBalance: 2,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('PatientFilters Domain Model', () {
    test('verifies isEmpty and isNotEmpty properties', () {
      const empty = PatientFilters();
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);

      const withClinic = PatientFilters(clinic: ClinicLocation.tagamoa);
      expect(withClinic.isEmpty, isFalse);
      expect(withClinic.isNotEmpty, isTrue);

      const withDoctor = PatientFilters(doctorId: 'doc-1');
      expect(withDoctor.isNotEmpty, isTrue);

      const withSearch = PatientFilters(search: 'Ahmed');
      expect(withSearch.isNotEmpty, isTrue);
    });

    test('verifies equality and copyWith', () {
      const f1 = PatientFilters(clinic: ClinicLocation.tagamoa, doctorId: 'doc-1');
      const f2 = PatientFilters(clinic: ClinicLocation.tagamoa, doctorId: 'doc-1');
      expect(f1, equals(f2));

      final f3 = f1.copyWith(search: 'John');
      expect(f3.clinic, ClinicLocation.tagamoa);
      expect(f3.doctorId, 'doc-1');
      expect(f3.search, 'John');

      final f4 = f3.copyWith(clearDoctorId: true);
      expect(f4.doctorId, isNull);
    });
  });

  group('Unavailable Count vs Genuine Zero Count in UI', () {
    testWidgets('PatientListHeader distinguishes null count from zero count', (tester) async {
      // 1. Genuine Zero: Displays '0'
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientListHeader(
              totalCount: 0,
              searchQuery: '',
              onSearchChanged: (_) {},
              onFilterTap: () {},
              activeFiltersCount: 0,
              canCreatePatient: false,
              onNewPatientTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);

      // 2. Unavailable Count (null): Does not render '0' badge
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientListHeader(
              totalCount: null,
              searchQuery: '',
              onSearchChanged: (_) {},
              onFilterTap: () {},
              activeFiltersCount: 0,
              canCreatePatient: false,
              onNewPatientTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('0'), findsNothing);
      expect(find.text('Patients'), findsOneWidget);
    });

    testWidgets('PatientTablePagination distinguishes null count from zero count', (tester) async {
      // 1. Genuine Zero: 'Showing 0 to 0 of 0 patients'
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientTablePagination(
              currentPage: 1,
              totalPages: 1,
              totalCount: 0,
              pageSize: 30,
              hasPrevious: false,
              hasNext: false,
              onPrevious: () {},
              onNext: () {},
            ),
          ),
        ),
      );
      expect(find.text('Showing 0 to 0 of 0 patients'), findsOneWidget);

      // 2. Unavailable Count (null): 'Showing 1 to 30 patients' without 'of 0'
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientTablePagination(
              currentPage: 1,
              totalPages: 1,
              totalCount: null,
              pageSize: 30,
              hasPrevious: false,
              hasNext: false,
              onPrevious: () {},
              onNext: () {},
            ),
          ),
        ),
      );
      expect(find.text('Showing 1 to 30 patients'), findsOneWidget);
      expect(find.textContaining('of 0'), findsNothing);
    });
  });

  group('Patient Filter Combinations (Branch + Doctor and Search + Branch + Doctor)', () {
    test('passes Branch + Doctor combination to both getAll and count queries', () async {
      final mockRepo = _MockPatientRepository();
      mockRepo.getAllResult = Result.success([_createPatient('1', 'Ali')]);
      mockRepo.countResult = const Result.success(1);

      final container = ProviderContainer(
        overrides: [
          patientRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(patientListProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(patientListProvider.notifier);
      await container.read(patientListProvider.future);

      notifier.applyFilters(
        clinic: ClinicLocation.tagamoa,
        doctorId: 'doc-777',
        orderBy: 'full_name',
        ascending: true,
      );
      await container.pump();

      expect(mockRepo.lastGetAllFilters?.clinic, ClinicLocation.tagamoa);
      expect(mockRepo.lastGetAllFilters?.doctorId, 'doc-777');
      expect(mockRepo.lastGetAllFilters?.search, isNull);

      expect(mockRepo.lastCountFilters?.clinic, ClinicLocation.tagamoa);
      expect(mockRepo.lastCountFilters?.doctorId, 'doc-777');
      expect(mockRepo.lastCountFilters?.search, isNull);
    });

    test('passes Search + Branch + Doctor combination to both getAll and count queries', () async {
      final mockRepo = _MockPatientRepository();
      mockRepo.getAllResult = Result.success([_createPatient('1', 'Ahmed Hatem')]);
      mockRepo.countResult = const Result.success(1);

      final container = ProviderContainer(
        overrides: [
          patientRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(patientListProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(patientListProvider.notifier);
      await container.read(patientListProvider.future);

      notifier.applyFilters(
        clinic: ClinicLocation.masrElgedida,
        doctorId: 'doc-888',
        orderBy: 'full_name',
        ascending: true,
      );
      notifier.searchNow('Ahmed Hatem');
      await container.pump();

      expect(mockRepo.lastGetAllFilters?.clinic, ClinicLocation.masrElgedida);
      expect(mockRepo.lastGetAllFilters?.doctorId, 'doc-888');
      expect(mockRepo.lastGetAllFilters?.search, 'Ahmed Hatem');

      expect(mockRepo.lastCountFilters?.clinic, ClinicLocation.masrElgedida);
      expect(mockRepo.lastCountFilters?.doctorId, 'doc-888');
      expect(mockRepo.lastCountFilters?.search, 'Ahmed Hatem');
    });

    test('leaves totalCount as null instead of 0 when count query fails', () async {
      final mockRepo = _MockPatientRepository();
      mockRepo.getAllResult = Result.success([_createPatient('1', 'Tarek')]);
      mockRepo.countResult = Result.failure(const DatabaseException(code: 'db/timeout', message: 'Count timed out'));

      final container = ProviderContainer(
        overrides: [
          patientRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(patientListProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(patientListProvider.notifier);
      final patients = await container.read(patientListProvider.future);

      expect(patients.length, 1);
      expect(notifier.totalCount, isNull);
    });
  });

  group('Stale Async Protection in PatientList Notifier', () {
    test('stale slower search request does not overwrite results from newer search request', () async {
      final mockRepo = _MockPatientRepository();
      final slowCompleter = Completer<Result<List<Patient>>>();
      final slowCountCompleter = Completer<Result<int>>();

      final container = ProviderContainer(
        overrides: [
          patientRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(patientListProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(patientListProvider.notifier);
      await container.read(patientListProvider.future);

      // 1. Trigger Request #1 (Slow)
      mockRepo.getAllCompleter = slowCompleter;
      mockRepo.countCompleter = slowCountCompleter;
      notifier.searchNow('SlowQuery');

      // 2. Trigger Request #2 (Fast)
      mockRepo.getAllCompleter = null;
      mockRepo.countCompleter = null;
      mockRepo.getAllResult = Result.success([_createPatient('2', 'Fast Result')]);
      mockRepo.countResult = const Result.success(1);
      notifier.searchNow('FastQuery');
      await pumpEventQueue();

      // Verify Request #2 is currently in state
      expect(container.read(patientListProvider).value?.first.fullName, 'Fast Result');
      expect(notifier.totalCount, 1);

      // 3. Now let Request #1 resolve later
      slowCompleter.complete(Result.success([_createPatient('1', 'Stale Result')]));
      slowCountCompleter.complete(const Result.success(999));
      await pumpEventQueue();

      // State and totalCount MUST NOT be overwritten by Request #1
      expect(container.read(patientListProvider).value?.first.fullName, 'Fast Result');
      expect(notifier.totalCount, 1);
    });
  });
}
