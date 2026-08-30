import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_condition.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/condition_catalog_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_detail_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_form_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/condition_picker_sheet.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/region_filter_dropdown.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_programs.dart';

class _FakeConditionCatalogRepo implements ConditionCatalogRepository {
  @override
  Future<Result<List<ConditionCatalog>>> getAllConditions() async {
    return const Result.success([
      ConditionCatalog(
        id: 'c1',
        region: BodyRegion.shoulder,
        conditionName: 'Shoulder impingement syndrome',
      ),
      ConditionCatalog(
        id: 'c2',
        region: BodyRegion.lumbarSpine,
        conditionName: 'Lumbar disc herniation',
      ),
    ]);
  }

  @override
  Future<Result<List<ConditionCatalog>>> getConditionsByRegion(
    BodyRegion region,
  ) async {
    final all = await getAllConditions();
    return all.when(
      success: (data) =>
          Result.success(data.where((c) => c.region == region).toList()),
      failure: (e) => Result.failure(e),
    );
  }
}

class _FakeProgramRepo implements ProgramRepository {
  final List<PatientProgram> programs = [];

  @override
  Future<Result<List<PatientProgram>>> getProgramsForPatient(
    String patientId,
  ) async {
    return Result.success(
      programs.where((p) => p.patientId == patientId).toList(),
    );
  }

  @override
  Future<Result<PatientProgram?>> getProgramById(String programId) async {
    return Result.success(
      programs.where((p) => p.id == programId).firstOrNull,
    );
  }

  @override
  Future<Result<PatientProgram>> createProgram({
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    List<ProgramAttachment>? pendingAttachments,
  }) async {
    final prog = PatientProgram(
      id: 'p1',
      patientId: patientId,
      createdBy: 'doc1',
      examination: examination,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      conditions: const [],
    );
    programs.add(prog);
    return Result.success(prog);
  }

  @override
  Future<Result<PatientProgram>> updateProgram({
    required String programId,
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    ProgramStatus? status,
    List<ProgramAttachment>? pendingAttachments,
  }) async =>
      Result.success(programs.first);

  @override
  Future<Result<void>> updateProgramStatus({
    required String programId,
    required ProgramStatus status,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteProgram(String programId) async =>
      const Result.success(null);
}

class _StaticUser extends CurrentUser {
  _StaticUser(this._user);
  final Staff? _user;
  @override
  Future<Staff?> build() async => _user;
}

Widget _wrap(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  final senior = Staff(
    id: 's1',
    fullName: 'Senior Doctor',
    email: 's@clinic.com',
    role: UserRole.doctor,
    isSenior: true,
    createdAt: DateTime(2026),
  );

  final testPatient = Patient(
    id: 'pat-1',
    fullName: 'Ziad Abaza',
    phoneNumber: '01012345678',
    clinic: ClinicLocation.tagamoa,
    createdAt: DateTime(2026),
  );

  testWidgets('PatientTabPrograms renders empty state when no programs exist',
      (tester) async {
    final fakeProgRepo = _FakeProgramRepo();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(() => _StaticUser(senior)),
        programRepositoryProvider.overrideWithValue(fakeProgRepo),
      ],
    );

    await tester.pumpWidget(
      _wrap(PatientTabPrograms(patient: testPatient), container),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noProgramsRecorded), findsOneWidget);
    expect(find.text(AppStrings.newProgram), findsWidgets);
  });

  testWidgets('ConditionPickerSheet allows searching and selecting conditions',
      (tester) async {
    final fakeCatalog = _FakeConditionCatalogRepo();
    final container = ProviderContainer(
      overrides: [
        conditionCatalogRepositoryProvider.overrideWithValue(fakeCatalog),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        const ConditionPickerSheet(selectedConditionIds: {}),
        container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shoulder impingement syndrome'), findsOneWidget);
    expect(find.text('Lumbar disc herniation'), findsOneWidget);

    await tester.tap(find.text('Shoulder impingement syndrome'));
    await tester.pumpAndSettle();

    expect(find.text('Apply (1)'), findsOneWidget);
  });

  testWidgets('ProgramDetailScreen displays program information accurately',
      (tester) async {
    final program = PatientProgram(
      id: 'prog-1',
      patientId: 'pat-1',
      createdBy: 'doc1',
      examination: 'Full flexion with mild pain at end range',
      imagingNotes: 'MRI indicates mild L4-L5 bulge',
      createdAt: DateTime(2026, 8, 30),
      updatedAt: DateTime(2026, 8, 30),
      conditions: [
        ProgramCondition(
          id: 'pc1',
          programId: 'prog-1',
          conditionId: 'c1',
          condition: const ConditionCatalog(
            id: 'c1',
            region: BodyRegion.shoulder,
            conditionName: 'Shoulder impingement syndrome',
          ),
        ),
      ],
    );

    final fakeProgRepo = _FakeProgramRepo()..programs.add(program);
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(() => _StaticUser(senior)),
        programRepositoryProvider.overrideWithValue(fakeProgRepo),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        ProgramDetailScreen(
          patientId: 'pat-1',
          programId: 'prog-1',
          initialProgram: program,
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.program), findsOneWidget);
    expect(find.text('Shoulder'), findsOneWidget);
    expect(find.text('Shoulder impingement syndrome'), findsOneWidget);
    expect(find.text('Full flexion with mild pain at end range'), findsOneWidget);
    expect(find.text('MRI indicates mild L4-L5 bulge'), findsOneWidget);
  });

  testWidgets('ProgramFormScreen renders form content with pinned bottom save bar', (tester) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      _wrap(const ProgramFormScreen(patientId: 'pat-1'), container),
    );
    await tester.pumpAndSettle();

    // Body must render (a collapsed body means the save bar swallowed it).
    expect(find.text(AppStrings.selectInjuries), findsOneWidget);
    expect(find.byType(ListView), findsWidgets);

    // Save button must be pinned to the bottom edge, not floating mid-screen.
    final saveCenter = tester.getCenter(find.text(AppStrings.save));
    final screenHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;
    expect(saveCenter.dy, greaterThan(screenHeight * 0.8));
  });

  testWidgets('RegionFilterDropdown renders anatomical regions correctly',
      (tester) async {
    BodyRegion? selected;
    final container = ProviderContainer();

    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => RegionFilterDropdown(
            selectedRegion: selected,
            onChanged: (val) => setState(() => selected = val),
          ),
        ),
        container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.allBodyRegions), findsOneWidget);
  });
}
